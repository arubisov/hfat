function [ X, Q, T ] = cts_backtest_fullyear( data, h, deltaminus, deltaplus, ...
                num_bins, dt_Z, Qmax, alpha, kappa, xi, fs_T, fs_dt, rho )

    T1 = 9.5 * 3600000;
    T2 = 16 * 3600000;

    [ pricechgseries ] = data.dS;
    [~, binseries] = histc(data.IBavg, rho);
    [ oneDseries ] = get1Dseries( binseries, pricechgseries, num_bins );
    
    day_size = (T2-T1)/dt_Z;
    num_days = size(data.dS,1) / day_size;
    
    X = NaN(1,num_days);
    Q = NaN(1,num_days);
    T = zeros(num_days, 2); %idx 1=MO, 2=LO
    
    to_idx = 0;
    
    for day = 1 : num_days
        fprintf('day %d\n',day);
        from_idx = to_idx + 1;
        to_idx = day * day_size;
    
        % set up valuation prices. starts at zero.
        data.dS(from_idx:to_idx,2) = cumsum(data.dS(from_idx:to_idx,1));
        data.dS(from_idx:to_idx,2) = data.dS(from_idx:to_idx,2) + 30 * 10000;
        
        hist_Q = zeros(1,day_size);
        q = 0;
        cash = 0;
        
        dplus = Inf;
        dminus = Inf;
        
        for i = from_idx:to_idx
            z = round(oneDseries(i));
            t = T1 + dt_Z * mod(i,day_size);

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
            b = data.MOsum(i,4);
            s = data.MOsum(i,5);
            MOseq = wtdrandsampleWR(2,b+s,[b s]);
            for MO = 1 : numel(MOseq)
                if MO == 2 % MO Sell
                    u = rand();
                    % did we get lifted?
                    if u < exp(-kappa*dplus)
                        % market order sell, so we buy at delta^+ (buy) price
                        q = q + 1;
                        T(day,2) = T(day,2) + 1;
                        price = data.dS(i,2)/10000 - xi - dplus;
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
                        price = data.dS(i,2)/10000 + xi + dminus;
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
                price = data.dS(i,2)/10000 + xi;
                cash = cash - price;
                [ dplus, dminus ] = repost(deltaplus, deltaminus, t_h, z, q, Qmax);
            end

            while checksellcondition(h,t_h,z,q,xi,Qmax)
                % execute sell MO
                q = q - 1;
                T(day,1) = T(day,1) + 1;
                price = data.dS(i,2)/10000 - xi;
                cash = cash + price;
                [ dplus, dminus ] = repost(deltaplus, deltaminus, t_h, z, q, Qmax);
            end

%             if q > 0,       price = data.dS(i,2)/10000 - xi;
%             elseif q < 0,   price = data.dS(i,2)/10000 + xi;
%             else            price = 0; 
%             end
%             % get NPV.
%             X(day,i) = cash + q*price;
            hist_Q(i) = q;
        end

        % terminal liqudation
        if q > 0,       price = data.dS(i,2)/10000 - xi;
        elseif q < 0,   price = data.dS(i,2)/10000 + xi;
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
    X = 1/30 * X;
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
