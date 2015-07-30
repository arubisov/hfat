function [ cash, q ] = dscr_backtest( data, h, deltaminus, deltaplus )
    global kappa
    global xi
    global num_bins
    global G
    global Qrange
    global avg_method
    global dt_Z

    fs_T = 50;
    fs_dt = 1;

    T1 = 9.5 * 3600000;
    T2 = 16 * 3600000;
    q = 0;
    cash = 0;
    
    [ binseries, pricechgseries, G, ~ ] = compute_G( data, dt_Z, num_bins, avg_method );
    [ oneDseries ] = get1Dseries( binseries, pricechgseries, num_bins );
    
    from = find(data.Event(:,1) >= T1, 1, 'first');
    to = find(data.Event(:,1) <= T2, 1, 'last');
    data.Event = data.Event(from:to,:);
    data.SellVolume = data.SellVolume(from:to,:);
    data.SellPrice = data.SellPrice(from:to,:);
    data.BuyVolume = data.BuyVolume(from:to,:);
    data.BuyPrice = data.BuyPrice(from:to,:);
    
    MO = ExtractMOs(data);
    % column 1: time of event
    % column 8: buy (-1) sell (+1) indicator
    MO = MO(:,[1 8]);
    MO = removeillegaltimes(MO);
    
    dplus = Inf;
    dminus = Inf;
    time_ctr = 1;
    MO_ctr = 1;
    t_h = 1;
    
    for i = 1:length(oneDseries)
        z = round(oneDseries(i));
        t = T1 + dt_Z*i;
        
        % at start of every dt, check whether our LO's had been lifted.
        try
            while MO(MO_ctr,1) <= t
                % did we get lifted?
                if MO(MO_ctr,2) == 1
                    u = rand();
                    if u < exp(-kappa*dplus)
                        % market order sell, so we buy at delta^+ (buy) price
                        q = q + 1;
                        price = data.BuyPrice(time_ctr,1)/10000 - dplus;
                        cash = cash - price;
                        %[ dplus, dminus ] = repost(deltaplus, deltaminus, t_h, z, q, Qrange);
                        dplus = Inf; dminus = Inf;
                    end
                else
                    u = rand();
                    if u < exp(-kappa*dminus)
                        % market order buy, so we sell at delta^- (buy) price
                        q = q - 1;
                        price = data.SellPrice(time_ctr,1)/10000 + dminus;
                        cash = cash + price;
                        %[ dplus, dminus ] = repost(deltaplus, deltaminus, t_h, z, q, Qrange);
                        dplus = Inf; dminus = Inf;
                    end
                end

                MO_ctr = MO_ctr + 1;
            end
        catch
            disp('MO: Reached end of day');
        end
        
        try
            while data.Event(time_ctr+1,1) <= t
                time_ctr = time_ctr+1;
            end
        catch
            disp('data.Event: Reached end of day.');
        end

        if t <= T2 - fs_T*1000
           t_h = 1;
        else
           t_h = round(size(deltaminus,1) -  (T2-t)/(1000*fs_dt));
        end
        
        [ dplus, dminus ] = repost(deltaplus, deltaminus, t_h, z, q, Qrange);
        
        % check whether we're executing any MOs?
        while h(t_h,z,find(Qrange == q+1)) - h(t_h,z,find(Qrange == q)) == 2*xi*(q >= 0)
            % execute buy MO
            q = q + 1;
            price = data.SellPrice(time_ctr,1)/10000;
            cash = cash - price;
            %if display, fprintf(fid, '[%d] {%d, %d, %d}.   Buy at %.2f (%d). [%d, %.2f].\n', t(timestep), IB_prev, DS_prev, IB_curr, price, price_time, q, cash); end;
            [ dplus, dminus ] = repost(deltaplus, deltaminus, t_h, z, q, Qrange);
        end
        
        while h(t_h,z,find(Qrange == q-1)) - h(t_h,z,find(Qrange == q)) == 2*xi*(q <= 0)
            % execute sell MO
            q = q - 1;
            price = data.BuyPrice(time_ctr,1)/10000;
            cash = cash + price;
            [ dplus, dminus ] = repost(deltaplus, deltaminus, t_h, z, q, Qrange);
        end
       
        
    end
        
        

end

function [ dplus, dminus ] = repost(deltaplus, deltaminus, t_h, z, q, Qrange)
    t_h = round(t_h);
    z = round(z);
    if q == -15
        dminus = Inf;
        dplus = deltaplus(t_h,z,1);
    elseif q == 15
        dplus = Inf;
        dminus = deltaminus(t_h,z,end);
    else
        dplus = deltaplus(t_h,z,find(Qrange == q, 1));
        dminus = deltaminus(t_h,z,find(Qrange == q, 1));
    end
end
