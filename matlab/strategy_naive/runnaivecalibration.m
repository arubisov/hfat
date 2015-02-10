% Determine optimal bin/imb/ds for a particular set of data, by maxmizing
% probability of trade.
function [fitnessmat,bin,imb,ds] = runnaivecalibration(data, ib_avg_method)

    bin_min = 3;
    bin_max = 10;
    bin_step = 1;
    bin_array = [bin_min : bin_step : bin_max];
    
    imb_min = 100;
    imb_max = 1000;
    imb_step = 100;
    imb_array = [imb_min : imb_step : imb_max];
    
%     ds_min = imb_min;
%     ds_max = imb_max;
%     ds_step = imb_step;
%     ds_array = [ds_min : ds_step : ds_max];
    
%     fitnessmat = NaN(length(bin_array), length(imb_array), length(ds_array));
    fitnessmat = NaN(length(bin_array), length(imb_array));

    fprintf('Running calibration and fitness testing...\n');
    reversestr = '';
    tic;
    for bin = bin_array
        for imb = imb_array
%             for ds = ds_min : ds_step : imb
                
                bin_ctr = (bin-bin_min)/bin_step + 1;
                imb_ctr = (imb-imb_min)/imb_step + 1;
%                 ds_ctr = (ds-ds_min)/ds_step + 1;
                
                % Previously calculated fitness via expected number of
                % successful trades.
                %[P_bid, ~, ~, ~, ~, N_bid] = computeprobabilitypricechange(data, imb, bin, ds);
                %fitnessmat(bin_ctr, imb_ctr, ds_ctr) = evalfitness(P_bid, N_bid);
                
                % Now calculate as highest return / sharpe
                fitnessmat(bin_ctr, imb_ctr) = evalfitness(data, imb, bin, imb, ib_avg_method);
                
                iter = imb_ctr + (bin_ctr-1)*length(imb_array);
                total_iter = (length(imb_array) * length(bin_array));

                msg = sprintf('Estimated time remaining: %d seconds\n', round(toc * (total_iter/iter - 1)));
                fprintf([reversestr, msg]);
                reversestr = repmat('\b', 1, length(msg));
%             end
        end
    end
    fprintf(reversestr);
    
    [maxval, maxindex] = max(fitnessmat(:));
    [bin,imb] = ind2sub(size(fitnessmat),maxindex);
    bin = bin_array(bin);
    imb = imb_array(imb);
    ds = imb;
    fprintf('Fitness maximized at bin=%d, dt_imbalance=%d, Intra-day Sharpe=%.3f\n',bin,imb,maxval);


function fitness = evalfitness(data, imb, bin, ds, ib_avg_method)
    %indices = (P_bid > 0.5);
    %indices(2,:,:) = 0;
    %
    %fitness = sum(P_bid(indices) .* N_bid(indices));

    [~,~,bookvalues] = naiveplustradingstrategy(data, imb, bin, ds, 'DUMMY', 0, 0, ib_avg_method);
    
    % intra-day sharpe ratio
    returns = (bookvalues(2:end) - bookvalues(1:end-1)) ./ bookvalues(1:end-1);
    idx = (isnan(returns) == 1) | (isinf(returns) == 1);
    returns(idx) = 0;
    fitness = mean(returns) / std(returns);