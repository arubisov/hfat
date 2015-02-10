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
    
function rho = createbins(num_bins, mu_IB, type)
    switch type
        case 1
            % create even interval bins
            rho = [-1 : 1/(num_bins/2) : 1]';
            rho(1) = -1.1;
        case 2
            % create even distribution bins (by percentiles)
            rho = NaN(num_bins + 1, 1);
            rho(1) = -1.1;
            rho(num_bins + 1) = 1.1;
            for bin = 1 : num_bins - 1
                rho(bin+1) = prctile(mu_IB, bin * 100 / num_bins);
            end
    end
        
    
function [t, mu_IB] = computeavgimbalance(data, dt, avg_method)

    T1 = 9.5 * 3600000;
    T2 = 16 * 3600000;
    t = [T1 + dt : dt : T2];    % these are the endpoints of avging intervals

    mu_IB = zeros(length(t),1);
    
    ctr = find(data.Event(:,1) >= T1, 1, 'first');
    
    switch avg_method
        case num2cell(1:3)
            num = avg_method;
            weights = ones(num,1);
        case num2cell(4:5)
            num = avg_method - 2;
            weights = exp(0.5*[0:-1:-(num-1)])';
    end
       
    IB = (data.BuyVolume(:,1:num) * weights - data.SellVolume(:,1:num) * weights) ./ (data.BuyVolume(:,1:num) * weights + data.SellVolume(:,1:num) * weights);

    

    for k = 1 : length(t)

        ctr_from = ctr;
        
        while data.Event(ctr,1) < t(k)
            ctr = ctr+1;
        end
        
        tau = data.Event(ctr_from:ctr,1);
        dtau = diff(tau);

        thisIB = IB(ctr_from:ctr);

        if ctr > ctr_from
            if sum(dtau) > 1
                mu_IB(k) = sum(dtau .* thisIB(1:end-1)) / sum(dtau);
            else
                mu_IB(k) = mean(thisIB);
            end
        else
            if k > 1
                mu_IB(k) = mu_IB(k-1);
            else
                mu_IB(k) = thisIB;
            end
        end

    end


function [bidchgseries, askchgseries] = computepricechanges(data, t, dt_price_chg)
    bidchgseries = zeros(length(t)-1,1);
    askchgseries = zeros(length(t)-1,1);
    
    ctr_from = 1;
    
    for k = 1 : length(t)-1
        
        while data.Event(ctr_from,1) < t(k)
            ctr_from = ctr_from + 1;
        end
        
        ctr = ctr_from;
        
        while data.Event(ctr,1) <= t(k) + dt_price_chg
            ctr = ctr+1;
        end
        ctr = ctr-1;

        if ctr > ctr_from
            bidchgseries(k) = data.BuyPrice(ctr,1) - data.BuyPrice(ctr_from,1);
            askchgseries(k) = data.SellPrice(ctr,1) - data.SellPrice(ctr_from,1);
        else
            bidchgseries(k) = 0;
            askchgseries(k) = 0;
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
        
        