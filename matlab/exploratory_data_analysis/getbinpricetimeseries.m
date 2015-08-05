%% Get CTMC generator matrices for the joint distribution (I, dS)
% data              data to run against
% dt_imbalance_avg  time increment over which to average imbalances
% num_bins          number of bins to cast the imbalances into
% dt_prive_chg      time increment over which to measure price change

function [t, binseries, pricechgseries, G, mu_IB] = getbinpricetimeseries(data, dt_imbalance_avg, num_bins, dt_price_chg, avg_method, early_close)
 
    % Imbalance Timeseries
    [t, mu_IB] = computeavgimbalance(data, dt_imbalance_avg, avg_method, early_close);

    % create bins for CTMC
    rho = createbins(num_bins, mu_IB, 3);

    [~, binseries] = histc(mu_IB, rho);
    
    % Price Change Timeseries
    [pricechgseries] = computepricechanges(data, t, dt_price_chg);
    
    binpriceseries = [binseries(1:end-1) sign(pricechgseries)];
    
    [ G ] = estimateCTMC2D( binpriceseries, num_bins, dt_imbalance_avg );
end
