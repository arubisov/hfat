function [ t, binseries, pricechgseries, G, mu_IB ] = ...
    compute_G( data, dt, num_bins, avg_method )
    
    % Imbalance Timeseries
    % t are the endpoints of averaging intervals, mu_IB gives the
    % time-weighted average imbalance over the interval of time of size dt
    % and ending at t. 
    [t, mu_IB] = computeavgimbalance(data, dt, avg_method);

    % create bins for CTMC. 
    % bintype = 1 creates evenly spaced bins symmetric around zero. 
    bintype = 1;
    rho = createbins(num_bins, mu_IB, bintype);

    [~, binseries] = histc(mu_IB, rho);
    
    % Price Change Timeseries
    pricechgseries = compute_pricechgseries(data, t);
    
    binpriceseries = [binseries(1:end) sign(pricechgseries)];
    
    G = estimateCTMC2D(binpriceseries, num_bins, dt);
    
end    

function [pricechgseries] = compute_pricechgseries(data, t)
    pricechgseries = zeros(length(t),1);
    T1 = 9.5 * 3600000;
    ctr = find(data.Event(:,1) >= T1, 1, 'first');
    
    for k = 1 : length(t)
        ctr_from = ctr;
        
        while data.Event(ctr,1) < t(k)
            ctr = ctr+1;
        end

        if ctr > ctr_from
            from_mean = (data.BuyPrice(ctr_from,1)+data.SellPrice(ctr_from,1))/2;
            to_mean = (data.BuyPrice(ctr,1)+data.SellPrice(ctr,1))/2;
            pricechgseries(k) = to_mean - from_mean;
        end
    end 
end
        
    
function [G] = estimateCTMC2D(series, num_bins, dt_avg)
    % Now we want to model the 2-D data (bin, $chg), so we'll instead
    % reduce it down to 1-D by multiplying. e.g. for 3 bins, we'll have:
    % 1 = bin 1, <0
    % 2 = bin 2, <0
    % 3 = bin 3, <0
    % 4 = bin 1, 0
    % 5 = bin 2, 0
    % 6 = bin 3, 0
    % 7 = bin 1, >0
    % 8 = bin 2, >0
    % 9 = bin 3, >0
    G = zeros(num_bins*3);
    
    % encode the 2d array into one: add 1 to the $chg, changing it from
    % [-1,0,1] to [0,1,2]. Then multiply by the 2x1 matrix [1;3] to get a
    % unique value in range [1,...,9]
    series(:,2) = series(:,2) + 1;
    series = series * [1;num_bins];

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

