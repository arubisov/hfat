% Cross-validate a 2D CTMC calibration.


for tickers = {'FARO','NTAP'}
    clearvars -except 'tickers';
    ticker = tickers{1};
    daterange = '';
    early_close_dates = [20130703;20131129;20131224];
    ib_avg_method = 5;
    num_bins = 5;
    dt = 100;

    listing = dir(sprintf('data-more/%s_%s*',ticker,daterange));
    %LR = NaN(numel(listing),5);

    fprintf('*** Beginning Cross-Validation ***\n');

    for file = 1 : numel(listing)

        % Calibrate run parameters off the first file.
        datafile = sprintf('./data-more/%s',listing(file).name);
        load(datafile);
        if all(size(data) == [1 1]) == 0, data = data{1,1}; end;

        % is this an early closure day?
        early_close = 0;
        thisdate = sscanf(listing(file).name,sprintf('%s_%s.mat',ticker,'%u'));
        if any(thisdate==early_close_dates), early_close = 1; end;

        [ t, binseries, pricechgseries, G, mu_IB ] = getbinpricetimeseries(data, dt, num_bins, dt, 5, early_close);
        binpriceseries = [binseries(1:end-1) sign(pricechgseries)];
        [ P ] = onestep( G, dt );

        % DETERMINE NUMBER OF TIMESTEPS n FOR P(t) TO CONVERGE
        errTol = 1e-10;
        convergence = false;
        n_conv = 1;
        next_A = P;

        while convergence == false
            n_conv = n_conv + 1;
            prev_A = next_A;
            next_A = expm(G*dt/1000*n_conv);
            absError = abs(next_A(:) - prev_A(:));
            convergence = all(absError < errTol);
        end



        % CROSS-VALIDATION
        for sub_ints = [2,4,8]
            n = floor(numel(pricechgseries) / sub_ints);
            dof = (sub_ints-1)*(num_bins*3)*(num_bins*3 - 1);
            err = 0;
            for k = 1 : sub_ints
                % inf gen of removed section   
                int_k = binpriceseries((k-1)*n + 1 : k*n , : );
                [ G_k ] = estimateCTMC2D( int_k, num_bins, dt );
                [ P_k ] = onestep( G_k, dt );
                [ N_k ] = numtransitions( int_k, num_bins );

                err = err + nansum(N_k(:) .* (log(P_k(:)) - log(P(:))));     
            end

            LR(file,log2(sub_ints)) = chi2pdf(2 * err,dof);
        end

        % lastly, using n_conv
        n = n_conv;
        sub_ints = floor(numel(pricechgseries) / n);
        dof = (sub_ints-1)*(num_bins*3)*(num_bins*3 - 1);
        err = 0;
        for k = 1 : sub_ints
            % inf gen of removed section   
            int_k = binpriceseries((k-1)*n + 1 : k*n , : );
            [ G_k ] = estimateCTMC2D( int_k, num_bins, dt );
            [ P_k ] = onestep( G_k, dt );
            [ N_k ] = numtransitions( int_k, num_bins );

            err = err + nansum(N_k(:) .* (log(P_k(:)) - log(P(:))));     
        end

        LR(file,4) = chi2pdf(2 * err,dof);
        LR(file,5) = n;

        %fprintf('finished: %d\n',file);
    end
    mLR = mean(LR);
    mLR(5) = round(mLR(5));
    mLR(1:4) = 1/1000 * round(mLR(1:4)*1000);
    fprintf('%s #bins=%d %dms\n',ticker, num_bins, dt);
    fprintf('%d & %0.3f & %0.3f & %0.3f & %0.3f\n',mLR(5),mLR(4),mLR(3),mLR(2),mLR(1));
end