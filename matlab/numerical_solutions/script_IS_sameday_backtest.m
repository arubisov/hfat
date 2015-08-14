% Run a single-day calibration and in-sample backtest.
%
% Master's Thesis
% Date  : 2015.07.29

tickers = {'FARO','NTAP','ORCL','INTC'};

for ticker = tickers
    % Initial set-up
    clearvars -except 'tickers';
    clc;
    %ticker = 'ORCL';
    ticker = ticker{1};
    daterange = '';
    fprintf('RUNNING SINGLE-DAY IN-SAMPLE BACKTEST\n');

    T1 = 9.5 * 3600000;
    T2 = 16 * 3600000;

    % Parameters
    dt_Z = 1000;        % Markov chain time window (in ms) for averaging.
    num_bins = 5;       % Markov chain number of bins.
    avg_method = 5;     % Order imbalance calculation method
    ds_method = 1;      % Calibration method ('correct' vs 'incorrect')
    kappa = 100;        % Fill probability constant, exp(-kappa*delta)
    alpha = 0.01;       % Liquidation penalty
    %xi = 0.01;          % Half the bid-ask spread
    phi = 0;            % Running inventory penalty (0 for continuous Case 1)

    % Explicit finite difference scheme setup
    Qmax = 20;          % max inventory (+/-)
    T = 100;            % time (in s) to compute function. assumes convergence beyond that.
    dt = 0.01;          % dt (in s) for first order derivative approximation.

    % Early close dates
    early_close_dates = [20130703;20131129;20131224];

    % Calibrate run parameters off the first file found in directory.
    listing = dir(sprintf('data-more/%s_%s*',ticker,daterange));

    Xcts = NaN(numel(listing),(T2-T1)/dt_Z);
    Xctsinv = NaN(numel(listing),(T2-T1)/dt_Z);
    Xctsnum = NaN(numel(listing),1);

    Xdscr = NaN(numel(listing),(T2-T1)/dt_Z);
    Xdscrinv = NaN(numel(listing),(T2-T1)/dt_Z);
    Xdscrnum = NaN(numel(listing),1);

    parfor file = 1 : numel(listing)
        datafile = sprintf('./data-more/%s',listing(file).name);
        data = load(datafile);
        data = data.data;
        if all(size(data) == [1 1]) == 0, data = data{1,1}; end;

        % is this an early closure day?
        thisdate = sscanf(listing(file).name,sprintf('%s_%s.mat',ticker,'%u'));
        if any(thisdate==early_close_dates)
            early_close = 1;
        else
            early_close = 0;
        end

        fprintf('Calibrating %s...\n', datafile);
        [ binseries, pricechgseries, G, ~ ] = ...
            compute_G( data, dt_Z, num_bins, avg_method, ds_method, early_close );
        [ oneDseries ] = get1Dseries( binseries, pricechgseries, num_bins );
        [ eta ] = compute_eta( oneDseries, pricechgseries, num_bins );
        [ muplus, muminus ] = compute_mu( data, oneDseries, dt_Z, num_bins );
        [ xi ] = compute_xi( data, early_close );

        % CONTINUOUS TIME
        fprintf('Solving Continuous DPEs and optimal deltas...\n');
        [ h_cts ] = cts_h_case1( phi, num_bins, Qmax, kappa, alpha, xi, ...
                                      G, eta, muplus, muminus, T, dt  );
        [ dp_cts, dm_cts ] = cts_delta_case1( h_cts, Qmax, kappa, xi );

        fprintf('Running continuous in-sample backtesting...\n');
        % Note we must use the 'correct' ds_method = 1.
        [ X_cts, Q_cts, numtrades_cts ] = cts_backtest( data, h_cts, dm_cts, dp_cts, ...
                       num_bins, avg_method, 1, dt_Z, Qmax, alpha, kappa, xi, T, dt, early_close );

        Xcts(file,:) = X_cts;
        Xctsinv(file,:) = Q_cts;
        Xctsnum(file) = numtrades_cts;
        
        % DISCRETE TIME
        fprintf('Solving Discrete DPEs and optimal deltas...\n');
        [ P ] = onestep( G, dt_Z );
        [ h_dscr, dp_dscr, dm_dscr ] = dscr_h( num_bins, Qmax, kappa, alpha, xi, ...
                              P, eta, muplus, muminus, T, dt_Z/1000);

        fprintf('Running discrete in-sample backtesting...\n');
        % Note we must use the 'correct' ds_method = 1.
        [ X_dscr, Q_dscr, numtrades_dscr ] = cts_backtest( data, h_dscr, dm_dscr, dp_dscr, ...
                       num_bins, avg_method, 1, dt_Z, Qmax, alpha, kappa, xi, T, dt_Z/1000, early_close );
        
        Xdscr(file,:) = X_dscr;
        Xdscrinv(file,:) = Q_dscr;
        Xdscrnum(file) = numtrades_dscr;
        
    end

    t = [T1 + dt_Z : dt_Z : T2];
    t = t/3600000;
    figure();
    hold on
    plot(t,nanmean(Xcts,1));
    plot(t,nanmean(Xdscr,1));
    hold off
    save(sprintf('%s-stoch-IS.mat',ticker), ...
        'Xcts','Xctsinv','Xctsnum','Xdscr','Xdscrinv','Xdscrnum');
end