% Determine optimal bin/imb/ds for a particular set of data, by maxmizing
% probability of trade.
function [fitnessmat,bin,imb,ds] = runnaivecalibration(data)

    bin_min = 4;
    bin_max = 4;
    bin_step = 1;
    bin_array = [bin_min : bin_step : bin_max];
    
    imb_min = 100;
    imb_max = 1000;
    imb_step = 100;
    imb_array = [imb_min : imb_step : imb_max];
    
    ds_min = imb_min;
    ds_max = imb_max;
    ds_step = imb_step;
    ds_array = [ds_min : ds_step : ds_max];
    
    fitnessmat = NaN(length(bin_array), length(imb_array), length(ds_array));

    fprintf('Running calibration and fitness testing...\n');
    reversestr = '';
    tic;
    for bin = bin_array
        for imb = imb_array
            for ds = imb : ds_step : imb
                
                bin_ctr = (bin-bin_min)/bin_step + 1;
                imb_ctr = (imb-imb_min)/imb_step + 1;
                ds_ctr = (ds-ds_min)/ds_step + 1;
                
                % Previously calculated fitness via expected number of
                % successful trades.
                %[P_bid, ~, ~, ~, ~, N_bid] = computeprobabilitypricechange(data, imb, bin, ds);
                %fitnessmat(bin_ctr, imb_ctr, ds_ctr) = evalfitness(P_bid, N_bid);
                
                % Now calculate as highest return / sharpe
                fitnessmat(bin_ctr, imb_ctr, ds_ctr) = evalfitness(data, imb, bin, ds);
                
                iter = ds_ctr + (imb_ctr-1)*length(ds_array) + (bin_ctr-1)*length(imb_array)*length(ds_array);
                total_iter = (length(imb_array) * length(bin_array) * length(ds_array));

                msg = sprintf('Estimated time remaining: %d seconds\n', round(toc * (total_iter/iter - 1)));
                fprintf([reversestr, msg]);
                reversestr = repmat('\b', 1, length(msg));
            end
        end
    end
    fprintf(reversestr);
    
    [maxval, maxindex] = max(fitnessmat(:));
    [bin,imb,ds] = ind2sub(size(fitnessmat),maxindex);
    bin = bin_array(bin);
    imb = imb_array(imb);
    ds = ds_array(ds);
    fprintf('Fitness maximized at bin=%d, dt_imbalance=%d, dt_price=%d, Intra-day Sharpe=%.2f\n',bin,imb,ds,maxval);


function fitness = evalfitness(data, imb, bin, ds)
    %indices = (P_bid > 0.5);
    %indices(2,:,:) = 0;
    %
    %fitness = sum(P_bid(indices) .* N_bid(indices));

    [~,~,bookvalues,~] = naivetradingstrategy(data, imb, bin, ds, 'DUMMY', 0, 0);
    
    % intra-day sharpe ratio
    returns = (bookvalues(2:end) - bookvalues(1:end-1)) ./ bookvalues(1:end-1);
    idx = (isnan(returns) == 1) | (isinf(returns) == 1);
    returns(idx) = 0;
    fitness = mean(returns) / std(returns);