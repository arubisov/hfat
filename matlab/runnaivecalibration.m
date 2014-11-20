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

    h = waitbar(0,'Running calibration and fitness testing...');
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
                %fprintf('Estim Time Remaining: %d seconds\n', toc * (total_iter/iter - 1)); 
                waitbar(iter / total_iter, h, sprintf('Running calibration and fitness testing...\n Estimated time remaining: %d seconds', round(toc * (total_iter/iter - 1))));
            end
        end
    end
    
    close(h);


function fitness = evalfitness(P_bid, N_bid)
    indices = (P_bid > 0.5);
    indices(2,:,:) = 0;
    
    fitness = sum(P_bid(indices) .* N_bid(indices));