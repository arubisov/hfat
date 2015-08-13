% Run an in-sample backtest with all the goodies detailed.
function [ cash, q, hist_X, hist_Q, hist_Z, hist_Sb, hist_Sa, hist_dp, hist_dm, hist_their_Mb, ...
    hist_their_Ms, hist_our_Mb, hist_our_Ms, hist_Fillb, hist_Fills ] = cts_backtest_single( data, h, ...
                deltaminus, deltaplus, num_bins, avg_method, ds_method, ...
                dt_Z, Qmax, alpha, kappa, xi, fs_T, fs_dt, rho )

    T1 = 9.5 * 3600000;
    T2 = 16 * 3600000;
    q = 0;
    cash = 0;
    
    [ binseries, pricechgseries, ~, ~ ] = compute_G( data, dt_Z, num_bins, avg_method, ds_method, 0, rho );
    [ oneDseries ] = get1Dseries( binseries, pricechgseries, num_bins );
    
    hist_X = NaN(1,length(oneDseries));
    hist_Q = NaN(1,length(oneDseries));
    hist_Z = NaN(1,length(oneDseries));
    hist_Sb = NaN(1,length(oneDseries));
    hist_Sa = NaN(1,length(oneDseries));
    hist_dp = NaN(1,length(oneDseries));
    hist_dm = NaN(1,length(oneDseries));
    hist_their_Mb = NaN(1,length(oneDseries));   
    hist_their_Ms = NaN(1,length(oneDseries));
    hist_our_Mb = NaN(1,length(oneDseries));
    hist_our_Ms = NaN(1,length(oneDseries));
    hist_Fillb = NaN(1,length(oneDseries));
    hist_Fills = NaN(1,length(oneDseries));
    
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
    % column 6: average executed price per share
    MO = MO(:,[1 8 6]);
    MO = removeillegaltimes(MO);
    
    dplus = NaN;
    dminus = NaN;
    time_ctr = 1;
    MO_ctr = 1;
    
    for i = 1:length(oneDseries)
        z = round(oneDseries(i));
        t = T1 + dt_Z*i;
        hist_Z(i) = mod(z,num_bins);
        if hist_Z(i) == 0, hist_Z(i) = num_bins; end
        
        % at start of every dt, check whether our LO's had been lifted.
        try
            while MO(MO_ctr,1) <= t
                % did we get lifted?
                if MO(MO_ctr,2) == 1
                    hist_their_Ms(i) = MO(MO_ctr,3)/10000;
                    u = rand();
                    if u < exp(-kappa*dplus)
                        % market order sell, so we buy at delta^+ (buy) price
                        q = q + 1;
                        price = data.BuyPrice(time_ctr,1)/10000 - dplus;
                        cash = cash - price;
                        %[ dplus, dminus ] = repost(deltaplus, deltaminus, t_h, z, q, Qmax);
                        dplus = Inf; dminus = Inf;
                        hist_Fillb(i) = 1;
                    end
                else
                    hist_their_Mb(i) = MO(MO_ctr,3)/10000;
                    u = rand();
                    if u < exp(-kappa*dminus)
                        % market order buy, so we sell at delta^- (buy) price
                        q = q - 1;
                        price = data.SellPrice(time_ctr,1)/10000 + dminus;
                        cash = cash + price;
                        %[ dplus, dminus ] = repost(deltaplus, deltaminus, t_h, z, q, Qmax);
                        dplus = Inf; dminus = Inf;
                        hist_Fills(i) = 1;
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
            hist_our_Mb(i) = price;
            %if display, fprintf(fid, '[%d] {%d, %d, %d}.   Buy at %.2f (%d). [%d, %.2f].\n', t(timestep), IB_prev, DS_prev, IB_curr, price, price_time, q, cash); end;
            [ dplus, dminus ] = repost(deltaplus, deltaminus, t_h, z, q, Qmax);
        end
        
        while checksellcondition(h,t_h,z,q,xi,Qmax)
            % execute sell MO
            q = q - 1;
            price = data.BuyPrice(time_ctr,1)/10000;
            cash = cash + price;
            hist_our_Ms(i) = price;
            [ dplus, dminus ] = repost(deltaplus, deltaminus, t_h, z, q, Qmax);
        end
        
        if q > 0,       price = data.BuyPrice(end,1)/10000;
        elseif q < 0,   price = data.SellPrice(end,1)/10000;
        else            price = 0; 
        end
        
        hist_Sb(i) = data.BuyPrice(time_ctr,1)/10000;
        hist_Sa(i) = data.SellPrice(time_ctr,1)/10000;
        hist_X(i) = cash + q*price;
        hist_Q(i) = q;
        hist_dp(i) = dplus;
        hist_dm(i) = dminus;        
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
        dminus = NaN;
        dplus = deltaplus(t_h,z,1);
    elseif q == Qmax
        dplus = NaN;
        dminus = deltaminus(t_h,z,end);
    else
        qidx = Qmax + 1 + q;
        dplus = deltaplus(t_h,z,qidx);
        dminus = deltaminus(t_h,z,qidx);
    end
end
