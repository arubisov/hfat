% Calculate generator matrix G, 1D Markov chain series, and imbalance bins.
function [ binseries, pricechgseries, G, rho ] = ...
    compute_G_annual( data, num_bins, ds_method )

    % ds_method = 1: this is the 'correct', or Markovian, method for
    % computing price change. t is the endpoint of the interval, and the
    % value is the price change from t-s to t. 
    % ds_method = 2: the 'incorrect', non-Markovian, lookahead price change
    % method. at endpoint t, value is change from t to t+s.
    if ds_method == 1
        pricechgseries = data.dS;
    elseif ds_method == 2
        pricechgseries = data.dS(2:end);
        data.IBavg = data.IBavg(1:end-1);
    end

    % create bins for CTMC. 
    % bintype = 1 creates evenly spaced bins symmetric around zero. 
    bintype = 3;
    rho = createbins(num_bins, data.IBavg, bintype);

    [~, binseries] = histc(data.IBavg, rho);
    
    binpricechgseries = get1Dseries( binseries, pricechgseries, num_bins );
    
    G = estimateCTMC2D(binpricechgseries, num_bins);
    
end    

    
function [G] = estimateCTMC2D(series, num_bins)
    
    G = zeros(num_bins*3);
    
    % count number of regime switches
    for i = 2 : length(series)
        if series(i-1,:) == series(i,:), continue; end;

        G(series(i-1), series(i)) = G(series(i-1), series(i)) + 1;    
    end

    for row = 1 : num_bins*3
        total_occur = sum(series==row);
        if total_occur > 0
            G(row,:) = G(row,:) / (total_occur);
            G(row,row) = -sum(G(row,:));
        else
            G(row,:) = zeros(1,num_bins*3);
        end
    end


end

