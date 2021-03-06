function [ X, Q, T ] = backtest_AAPL( flag, data, ds_method, num_bins, dt_Z, Qmax, alpha, kappa, xi, fs_T, fs_dt )

    T1 = 9.5 * 3600000;
    T2 = 16 * 3600000;
    
    start_price = 30;
    
    % data cleanup! irregular behavior at EOD for each day.
    day_size = (T2-T1)/dt_Z;
    day_idx = day_size:day_size:numel(data.dS);
    data.dS(day_idx) = 0;
    % adjust for 7-to-1 stock split on day 108
    %data.dS(1:day_idx(108)) = data.dS(1:day_idx(108)) / 7;
    
    calib_days = 21;
    num_test_days = numel(day_idx) - calib_days;
    
    X = NaN(1,num_test_days);
    Q = NaN(1,num_test_days);
    T = zeros(num_test_days, 2); %idx 1=MO, 2=LO
    
    for day = 1 : num_test_days
        %%% CALIBRATE
        % calibrate annual here
        cal_from_idx = day_idx(day) - day_size + 1;
        cal_to_idx = day_idx(day-1+calib_days);
        calibdata = struct('dS',data.dS(cal_from_idx:cal_to_idx),'IBavg',data.IBavg(cal_from_idx:cal_to_idx),'MOsum',data.MOsum(cal_from_idx:cal_to_idx,:));
        [ binseries, pricechgseries, G, rho ] = compute_G_annual( calibdata, num_bins, ds_method, [] );
        [ oneDseries ] = get1Dseries( binseries, pricechgseries, num_bins );
        [ eta ] = compute_eta( oneDseries, pricechgseries, num_bins );
        [ muplus, muminus ] = compute_mu_annual( calibdata, oneDseries, num_bins );

        if flag == 0
            % CONTINUOUS TIME
            [ h ] = cts_h_case1( 0, num_bins, Qmax, kappa, alpha, xi, ...
                                          G, eta, muplus, muminus, fs_T, fs_dt  );
            [ deltaplus, deltaminus ] = cts_delta_case1( h, Qmax, kappa, xi );
        else
            % DISCRETE TIME
            [ P ] = onestep( G, dt_Z );
            [ h, deltaplus, deltaminus ] = dscr_h( num_bins, Qmax, kappa, alpha, xi, ...
                              P, eta, muplus, muminus, fs_T, fs_dt);
        end
        
        
        %%% RUN
        fprintf('day %d/%d\n',day,num_test_days);
        from_idx = cal_to_idx + 1;
        to_idx = day_idx(day+calib_days);
        
        [ pricechgseries ] = data.dS(from_idx:to_idx);
        [~, binseries] = histc(data.IBavg(from_idx:to_idx), rho);
        [ oneDseries ] = get1Dseries( binseries, pricechgseries, num_bins );
    
        % set up valuation prices. starts at zero.
        midprice = cumsum(data.dS(from_idx:to_idx));
        midprice = midprice + start_price * 10000;
        
        hist_Q = zeros(1,day_size);
        q = 0;
        cash = 0;
        
        dplus = Inf;
        dminus = Inf;
        
        for i = 1:day_size
            z = round(oneDseries(i));
            t = T1 + dt_Z;

            % at start of every dt, check whether our LO's had been lifted.
             %  MOsum - array containing info on market order arrivals during dT intervals:
             %          (:, 1) = Total Buy Volume;
             %          (:, 2) = Total Sell Volume;
             %          (:, 3) = Net Volume = Total Buy Volume - Total Buy Volume;
             %          (:, 4) = Number of Market Buy Orders;
             %          (:, 5) = Number of Market Sell Orders
            % first create array of MOs. we know only the numbers, not
            % sequence, so we'll have to work that out. let's do it like
            % this... throw random sequence of 1 or 2, for the total number
            % of orders, with probability weighted by the distribution of
            % the orders. see doc randsample. 
            % 1 == buy, 2 == sell.
            b = data.MOsum(cal_to_idx+i,4);
            s = data.MOsum(cal_to_idx+i,5);
            MOseq = wtdrandsampleWR(2,b+s,[b s]);
            for MO = 1 : numel(MOseq)
                if MO == 2 % MO Sell
                    u = rand();
                    % did we get lifted?
                    if u < exp(-kappa*dplus)
                        % market order sell, so we buy at delta^+ (buy) price
                        q = q + 1;
                        T(day,2) = T(day,2) + 1;
                        price = midprice(i)/10000 - xi - dplus;
                        cash = cash - price;
                        %[ dplus, dminus ] = repost(deltaplus, deltaminus, t_h, z, q, Qmax);
                        dplus = Inf; dminus = Inf;
                    end
                else
                    u = rand();
                    if u < exp(-kappa*dminus)
                        % market order buy, so we sell at delta^- (buy) price
                        q = q - 1;
                        T(day,2) = T(day,2) + 1;
                        price = midprice(i)/10000 + xi + dminus;
                        cash = cash + price;
                        %[ dplus, dminus ] = repost(deltaplus, deltaminus, t_h, z, q, Qmax);
                        dplus = Inf; dminus = Inf;
                    end
                end
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
                T(day,1) = T(day,1) + 1;
                price = midprice(i)/10000 + xi;
                cash = cash - price;
                [ dplus, dminus ] = repost(deltaplus, deltaminus, t_h, z, q, Qmax);
            end

            while checksellcondition(h,t_h,z,q,xi,Qmax)
                % execute sell MO
                q = q - 1;
                T(day,1) = T(day,1) + 1;
                price = midprice(i)/10000 - xi;
                cash = cash + price;
                [ dplus, dminus ] = repost(deltaplus, deltaminus, t_h, z, q, Qmax);
            end

            hist_Q(i) = q;
        end

        % terminal liqudation
        if q > 0,       price = midprice(i)/10000 - xi;
        elseif q < 0,   price = midprice(i)/10000 + xi;
        else
            price = 0;
            T(day,1) = T(day,1) - 1;
        end
        cash = cash + q*(price - alpha*q);
        T(day,1) = T(day,1) + 1;
        X(day) = cash;
        Q(day) = mean(hist_Q);
    end
    % normalize the NPVs
    X = 1/start_price * X;
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

function [ v ] = wtdrandsampleWR( n, k, w )
% Weighted random sample with replacement.
% n - samples from integers 1 to n
% k - number of samples to draw
% w - integer weights, a vector the same length as n

if k > sum(w), error('Cannot draw that many samples using that weight vector.'), end
if n ~= length(w), error('The vector of weights must have length n.'),end
v = zeros(1,k);
for i = 1 : k
    v(i) = randsample(n,1,true,w);
    w(v(i)) = w(v(i)) - 1;
end
end
