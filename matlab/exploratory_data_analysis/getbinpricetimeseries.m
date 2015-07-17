%% Get CTMC generator matrices for the joint distribution (I, dS)
% data              data to run against
% dt_imbalance_avg  time increment over which to average imbalances
% num_bins          number of bins to cast the imbalances into
% dt_prive_chg      time increment over which to measure price change

function [t, binseries, bidchgseries, askchgseries, G_binbid, G_binask, mu_IB] = getbinpricetimeseries(data, dt_imbalance_avg, num_bins, dt_price_chg, avg_method)
    
    if exist('data','var') == 0
        load('./data/ORCL_20130515.mat');
       % load('./data/FARO_20131016.mat');
    end

    if exist('dt_imbalance_avg','var') == 0
        dt_imbalance_avg = 1000;
    end
    
    if exist('num_bins','var') == 0
        num_bins = 3;
    end
    
    if exist('dt_price_chg','var') == 0
        dt_price_chg = 500;
    end
   
    % Imbalance Timeseries
    [t, mu_IB] = computeavgimbalance(data, dt_imbalance_avg, avg_method);

    % create bins for CTMC
    rho = createbins(num_bins, mu_IB, 2);

    [bin_count, binseries] = histc(mu_IB, rho);
    
    % Price Change Timeseries
    [bidchgseries, askchgseries] = computepricechanges(data, t, dt_price_chg);
    
    binbidseries = [binseries(1:end-1) sign(bidchgseries)];
    binaskseries = [binseries(1:end-1) sign(askchgseries)];
    
    G_binbid = estimateCTMC2D(binbidseries, num_bins, dt_imbalance_avg);
    G_binask = estimateCTMC2D(binaskseries, num_bins, dt_imbalance_avg);
    
    

        
    
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
        
        