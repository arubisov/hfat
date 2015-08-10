function [x,q,t] = run_OOS_strategy(strat, data, oosdata, dt_Z, num_bins, ...
    avg_method, early_close, oos_early_close, phi, kappa, alpha, Qmax, fs_T, fs_dt )
    switch strat
        case 1 % Naive
            % Calibrate P and rho from initial data
            [ P, ~, ~, ~, ~, rho ] = computeprobabilitypricechange( ...
                data, dt_Z, num_bins, dt_Z, avg_method, early_close, []);
                                
            % Run naive strategy on +1 week data
            [ x, q, t, ~ ] = naivetradingstrategy(oosdata, P, dt_Z, num_bins, dt_Z, 'foo', 0, oos_early_close, avg_method, rho);

        case 2 % Naive+
            % Calibrate P and rho from initial data
            [ P, ~, ~, ~, ~, rho ] = computeprobabilitypricechange( ...
                data, dt_Z, num_bins, dt_Z, avg_method, early_close, []);
            
            % Run naive+ strategy on +1 week data
            [ x, q, t ] = naiveplustradingstrategy(oosdata, P, dt_Z, num_bins, dt_Z, 'foo', 0, oos_early_close, avg_method, rho);

        case 3 % Naive++
            % Calibrate P and rho from initial data
            [ P, ~, ~, ~, ~, rho ] = computeprobabilitypricechange( ...
                data, dt_Z, num_bins, dt_Z, avg_method, early_close, []);
            
            % Run naive+ strategy on +1 week data
            [ x, q, t ] = naiveplusplustradingstrategy(oosdata, P, dt_Z, num_bins, dt_Z, 'foo', 0, oos_early_close, avg_method, rho);

        case 4 % Cts
            ds_method = 1;
            [ binseries, pricechgseries, G, rho ] = ...
                compute_G( data, dt_Z, num_bins, avg_method, ds_method, early_close, [] );
            [ oneDseries ] = get1Dseries( binseries, pricechgseries, num_bins );
            [ eta ] = compute_eta( oneDseries, pricechgseries, num_bins );
            [ muplus, muminus ] = compute_mu( data, oneDseries, dt_Z, num_bins );
            [ xi ] = compute_xi( data, early_close );
            
            % CONTINUOUS TIME
            % calibrate off original G
            [ h_cts ] = cts_h_case1( phi, num_bins, Qmax, kappa, alpha, xi, ...
                                          G, eta, muplus, muminus, fs_T, fs_dt  );
            [ dp_cts, dm_cts ] = cts_delta_case1( h_cts, Qmax, kappa, xi );

            % Note we must use the 'correct' ds_method = 1.
            [ x, q, t ] = cts_backtest( oosdata, h_cts, dm_cts, dp_cts, ...
                           num_bins, avg_method, 1, dt_Z, Qmax, alpha, kappa, xi, fs_T, fs_dt, oos_early_close, rho );

        case 5 % Dscr
            ds_method = 1;
            [ binseries, pricechgseries, G, rho ] = ...
                compute_G( data, dt_Z, num_bins, avg_method, ds_method, early_close, [] );
            [ oneDseries ] = get1Dseries( binseries, pricechgseries, num_bins );
            [ eta ] = compute_eta( oneDseries, pricechgseries, num_bins );
            [ muplus, muminus ] = compute_mu( data, oneDseries, dt_Z, num_bins );
            [ xi ] = compute_xi( data, early_close );

            % DISCRETE TIME
            [ P ] = onestep( G, dt_Z );
            [ h_dscr, dp_dscr, dm_dscr ] = dscr_h( num_bins, Qmax, kappa, alpha, xi, ...
                                  P, eta, muplus, muminus, fs_T, dt_Z/1000);

            % Note we must use the 'correct' ds_method = 1.
            [ x, q, t ] = cts_backtest( oosdata, h_dscr, dm_dscr, dp_dscr, ...
                           num_bins, avg_method, 1, dt_Z, Qmax, alpha, kappa, xi, fs_T, dt_Z/1000, oos_early_close, rho );
        case 6 % Cts w NMC
            ds_method = 2;
            [ binseries, pricechgseries, G, rho ] = ...
                compute_G( data, dt_Z, num_bins, avg_method, ds_method, early_close, [] );
            [ oneDseries ] = get1Dseries( binseries, pricechgseries, num_bins );
            [ eta ] = compute_eta( oneDseries, pricechgseries, num_bins );
            [ muplus, muminus ] = compute_mu( data, oneDseries, dt_Z, num_bins );
            [ xi ] = compute_xi( data, early_close );
            
            % CONTINUOUS TIME
            % calibrate off original G
            [ h_cts ] = cts_h_case1( phi, num_bins, Qmax, kappa, alpha, xi, ...
                                          G, eta, muplus, muminus, fs_T, fs_dt  );
            [ dp_cts, dm_cts ] = cts_delta_case1( h_cts, Qmax, kappa, xi );

            % Note we must use the 'correct' ds_method = 1.
            [ x, q, t ] = cts_backtest( oosdata, h_cts, dm_cts, dp_cts, ...
                           num_bins, avg_method, 1, dt_Z, Qmax, alpha, kappa, xi, fs_T, fs_dt, oos_early_close, rho );

        case 7 % Dscr w NMC
            ds_method = 2;
            [ binseries, pricechgseries, G, rho ] = ...
                compute_G( data, dt_Z, num_bins, avg_method, ds_method, early_close, [] );
            [ oneDseries ] = get1Dseries( binseries, pricechgseries, num_bins );
            [ eta ] = compute_eta( oneDseries, pricechgseries, num_bins );
            [ muplus, muminus ] = compute_mu( data, oneDseries, dt_Z, num_bins );
            [ xi ] = compute_xi( data, early_close );

            % DISCRETE TIME
            [ P ] = onestep( G, dt_Z );
            [ h_dscr, dp_dscr, dm_dscr ] = dscr_h( num_bins, Qmax, kappa, alpha, xi, ...
                                  P, eta, muplus, muminus, fs_T, dt_Z/1000);

            % Note we must use the 'correct' ds_method = 1.
            [ x, q, t ] = cts_backtest( oosdata, h_dscr, dm_dscr, dp_dscr, ...
                           num_bins, avg_method, 1, dt_Z, Qmax, alpha, kappa, xi, fs_T, dt_Z/1000, oos_early_close, rho );
    end

end