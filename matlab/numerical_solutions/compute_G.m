function [ binseries, pricechgseries, G, rho ] = ...
    compute_G( data, dt, num_bins, avg_method, ds_method, early_close )
% Calculate generator matrix G, 1D Markov chain series, and imbalance bins.
    
    % Imbalance Timeseries
    % t are the endpoints of averaging intervals, mu_IB gives the
    % time-weighted average imbalance over the interval of time of size dt
    % and ending at t. 
    [t, mu_IB] = computeavgimbalance(data, dt, avg_method, early_close);

    % create bins for CTMC. 
    % bintype = 1 creates evenly spaced bins symmetric around zero. 
    bintype = 3;
    rho = createbins(num_bins, mu_IB, bintype);

    [~, binseries] = histc(mu_IB, rho);
    
    % Price Change Timeseries
    % ds_method = 1: this is the 'correct', or Markovian, method for
    % computing price change. t is the endpoint of the interval, and the
    % value is the price change from t-s to t. 
    % ds_method = 2: the 'incorrect', non-Markovian, lookahead price change
    % method. at endpoint t, value is change from t to t+s.
    pricechgseries = compute_pricechgseries(data, t, ds_method);
    
    binpricechgseries = get1Dseries( binseries, pricechgseries, num_bins );
    
    G = estimateCTMC2D(binpricechgseries, num_bins, dt);
    
end    

function [pricechgseries] = compute_pricechgseries(data, t, ds_method)
    pricechgseries = zeros(length(t),1);
    T1 = 9.5 * 3600000;
    dt = t(2) - t(1);
    
    % easy way to accomplish lookahead price change: shift all times by the
    % time window. 
    if ds_method == 2
        data.Event(:,1) = data.Event(:,1) - dt;
    end
    
    ctr = find(data.Event(:,1) >= T1, 1, 'first');
    
    for k = 1 : length(t)
        ctr_from = ctr;
        
        % find first time >= t(k)
        while data.Event(ctr,1) < t(k), ctr = ctr+1; end
        if data.Event(ctr,1) > t(k), ctr = ctr-1; end

        if ctr > ctr_from
            from_mean = (data.BuyPrice(ctr_from,1)+data.SellPrice(ctr_from,1))/2;
            to_mean = (data.BuyPrice(ctr,1)+data.SellPrice(ctr,1))/2;
            pricechgseries(k) = to_mean - from_mean;
        end
    end
end
        
    
function [G] = estimateCTMC2D(series, num_bins, dt_avg)
    
    G = zeros(num_bins*3);
    
    % count number of regime switches
    for i = 2 : length(series)
        if series(i-1,:) == series(i,:), continue; end;

        G(series(i-1), series(i)) = G(series(i-1), series(i)) + 1;    
    end

    for row = 1 : num_bins*3
        total_occur = sum(series==row);
        if total_occur > 0
            G(row,:) = G(row,:) / (total_occur * dt_avg / 1000);
            G(row,row) = -sum(G(row,:));
        else
            G(row,:) = zeros(1,num_bins*3);
        end
    end


end

