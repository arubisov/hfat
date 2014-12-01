% Determine optimal bin/imb/ds for a particular set of data, by maxmizing
% probability of trade.
function fitnessmat = runnaivecalibration(data)

    bin_min = 3;
    bin_max = 9;
    bin_step = 1;
    bin_array = [bin_min : bin_step : bin_max];
    
    imb_min = 100;
    imb_max = 1000;
    imb_step = 100;
    imb_array = [imb_min : imb_step : imb_max];
    
    ds_min = 100;
    ds_max = 1000;
    ds_step = 100;
    ds_array = [ds_min : ds_step : ds_max];
    
    fitnessmat = zeros(length(bin_array), length(imb_array), length(ds_array));

    fprintf('Running calibration and fitness testing...\n');
    reversestr = '';
    tic;
    for bin = bin_array
        for imb = imb_array
            for ds = ds_min : ds_step : imb
                
                bin_ctr = (bin-bin_min)/bin_step + 1;
                imb_ctr = (imb-imb_min)/imb_step + 1;
                ds_ctr = (ds-ds_min)/ds_step + 1;
                
                [P_bid, ~, ~, ~, ~, N_bid] = computeprobabilitypricechange(data, imb, bin, ds);
                
                fitnessmat(bin_ctr, imb_ctr, ds_ctr) = evalfitness(P_bid, N_bid);
                
                iter = ds_ctr + (imb_ctr-1)*length(ds_array) + (bin_ctr-1)*length(imb_array)*length(ds_array);
                total_iter = (length(imb_array) * length(bin_array) * length(ds_array));

                msg = sprintf('Estimated time remaining: %d seconds\n', round(toc * (total_iter/iter - 1)));
                fprintf([reversestr, msg]);
                reversestr = repmat('\b', 1, length(msg));
            end
        end
    end
    fprintf(reversestr);
    
    [~, maxindex] = max(fitnessmat(:));
    [bin,imb,ds] = ind2sub(size(fitnessmat),maxindex);
    fprintf('Fitness maximized at bin=%d, dt_imbalance=%d, dt_price=%d\n',bin_array(bin),imb_array(imb),ds_array(ds));


function fitness = evalfitness(P_bid, N_bid)
    indices = (P_bid > 0.5);
    indices(2,:,:) = 0;
    
    fitness = sum(P_bid(indices) .* N_bid(indices));