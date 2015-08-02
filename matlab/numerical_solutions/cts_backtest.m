function [ hist_X, hist_Q ] = cts_backtest( data, h, deltaminus, deltaplus, ...
                num_bins, avg_method, ds_method, dt_Z, Qmax, alpha, ...
                kappa, xi, fs_T, fs_dt, early_close )

    T1 = 9.5 * 3600000;
    T2 = 16 * 3600000;
    q = 0;
    cash = 0;
    
    [ binseries, pricechgseries, ~, ~ ] = compute_G( data, dt_Z, num_bins, avg_method, ds_method, early_close );
    [ oneDseries ] = get1Dseries( binseries, pricechgseries, num_bins );
    
    hist_X = NaN(1,length(oneDseries));
    hist_Q = NaN(1,length(oneDseries));
    
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
    
    opening_mid = 1/20000 * (data.BuyPrice(1,1) + data.SellPrice(1,1));
    
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
                        %[ dplus, dminus ] = repost(deltaplus, deltaminus, t_h, z, q, Qmax);
                        dplus = Inf; dminus = Inf;
                    end
                else
                    u = rand();
                    if u < exp(-kappa*dminus)
                        % market order buy, so we sell at delta^- (buy) price
                        q = q - 1;
                        price = data.SellPrice(time_ctr,1)/10000 + dminus;
                        cash = cash + price;
                        %[ dplus, dminus ] = repost(deltaplus, deltaminus, t_h, z, q, Qmax);
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
        
        [ dplus, dminus ] = repost(deltaplus, deltaminus, t_h, z, q, Qmax);
        
        % check whether we're executing any MOs?
        while checkbuycondition(h,t_h,z,q,xi,Qmax)
            % execute buy MO
            q = q + 1;
            price = data.SellPrice(time_ctr,1)/10000;
            cash = cash - price;
            %if display, fprintf(fid, '[%d] {%d, %d, %d}.   Buy at %.2f (%d). [%d, %.2f].\n', t(timestep), IB_prev, DS_prev, IB_curr, price, price_time, q, cash); end;
            [ dplus, dminus ] = repost(deltaplus, deltaminus, t_h, z, q, Qmax);
        end
        
        while checksellcondition(h,t_h,z,q,xi,Qmax)
            % execute sell MO
            q = q - 1;
            price = data.BuyPrice(time_ctr,1)/10000;
            cash = cash + price;
            [ dplus, dminus ] = repost(deltaplus, deltaminus, t_h, z, q, Qmax);
        end
        
        if q > 0,       price = data.BuyPrice(end,1)/10000;
        elseif q < 0,   price = data.SellPrice(end,1)/10000;
        else            price = 0; 
        end
        % get NPV.
        hist_X(i) = cash + q*price;
        hist_Q(i) = q;
    end
    
    % terminal liqudation
    if q > 0,       price = data.BuyPrice(end,1)/10000;
    elseif q < 0,   price = data.SellPrice(end,1)/10000;
    else            price = 0; 
    end
    cash = cash + q*(price - alpha*q);
    q = 0;
    hist_X(i) = cash;
    hist_Q(i) = q;
    % normalize NPV
    hist_X = 1/opening_mid * hist_X;
end

function [ bool ] = checkbuycondition(h,t_h,z,q,xi,Qmax)
    if q == Qmax, bool = false; return; end

    qidx = Qmax + 1 + q;
    bool = h(t_h,z,qidx+1) - h(t_h,z,qidx) == 2*xi*(q >= 0);
end

function [ bool ] = checksellcondition(h,t_h,z,q,xi,Qmax)
    if q == -Qmax, bool = false; return; end

    qidx = Qmax + 1 + q;
    bool = h(t_h,z,qidx-1) - h(t_h,z,qidx) == 2*xi*(q <= 0);
end


function [ dplus, dminus ] = repost(deltaplus, deltaminus, t_h, z, q, Qmax)
    t_h = round(t_h);
    z = round(z);
    if q == -Qmax
        dminus = Inf;
        dplus = deltaplus(t_h,z,1);
    elseif q == Qmax
        dplus = Inf;
        dminus = deltaminus(t_h,z,end);
    else
        qidx = Qmax + 1 + q;
        dplus = deltaplus(t_h,z,qidx);
        dminus = deltaminus(t_h,z,qidx);
    end
end
