% Run annual calibration and out-of-sample backtest on the amalgamated annual data.
%
% Master's Thesis
% Date  : 2015.08.14
clear;
clc;

tickers = {'INTC'};
strategies = {'Cts','Dscr','Cts w nFPC','Dscr w nFPC'};

% Parameters
T1 = 9.5 * 3600000; % Start of day
T2 = 16 * 3600000;  % End of day
T3 = 13 * 3600000;  % Half day
dt_Z = 1000;        % Markov chain time window (in ms) for averaging.
num_bins = 5;       % Markov chain number of bins.
avg_method = 5;     % Order imbalance calculation method
kappa = 100;        % Fill probability constant, exp(-kappa*delta)
alpha = 0.01;       % Liquidation penalty
xi = 0.005;         % Half the bid-ask spread
phi = 0;            % Running inventory penalty (0 for continuous Case 1)

% Explicit finite difference scheme setup
Qmax = 20;          % max inventory (+/-)
fs_T = 600;         % time (in s) to compute function. assumes convergence beyond that.
fs_dt = 0.01;       % dt (in s) for first order derivative approximation.

X = NaN(numel(strategies),numel(tickers),249);
Q = NaN(numel(strategies),numel(tickers),249);
T = NaN(numel(strategies),numel(tickers),249,2);

tic;
for tickernum = 1 : numel(tickers)
    % Initial set-up
    ticker = tickers{tickernum};
    calibdata = load(sprintf('./data-more/fullyearconsolidated/%s_2013.mat',ticker));
    calibdata = calibdata.data;
    
    for ds_method = [1 2]
        
        % calibrate annual here
        [ binseries, pricechgseries, G, rho ] = compute_G_annual( calibdata, num_bins, ds_method, [] );
        [ oneDseries ] = get1Dseries( binseries, pricechgseries, num_bins );
        [ eta ] = compute_eta( oneDseries, pricechgseries, num_bins );
        [ muplus, muminus ] = compute_mu_annual( calibdata, oneDseries, num_bins );

        % CONTINUOUS TIME
        [ h_cts ] = cts_h_case1( phi, num_bins, Qmax, kappa, alpha, xi, ...
                                      G, eta, muplus, muminus, fs_T, fs_dt  );
        [ dp_cts, dm_cts ] = cts_delta_case1( h_cts, Qmax, kappa, xi );
        
        % DISCRETE TIME
        [ P ] = onestep( G, dt_Z );
        [ h_dscr, dp_dscr, dm_dscr ] = dscr_h( num_bins, Qmax, kappa, alpha, xi, ...
                              P, eta, muplus, muminus, fs_T, dt_Z/1000);
        
        toc;
        strat = 2*(ds_method-1)+1;
        label = '';
        if ds_method == 2,label = '_nFPC'; end
        plot_delta( dp_cts, fs_T, fs_dt, strcat('dp_cts',label) );
        plot_delta( dm_cts, fs_T, fs_dt, strcat('dm_cts',label) );
        plot_delta( dp_dscr, fs_T, 1, strcat('dp_dscr',label) );
        plot_delta( dm_dscr, fs_T, 1, strcat('dm_dscr',label) );
  
        data = load(sprintf('./data-more/fullyearconsolidated/%s_2014.mat',ticker));
        
        % data cleanup! irregular behavior at EOD for each day.
        day_size = (T2-T1)/dt_Z;
        data.dS(day_size:day_size:end) = 0;

        
        %%% RUN CTS
        [ x, q, t ] = cts_backtest_fullyear( data, h_cts, dm_cts, dp_cts, ...
            num_bins, dt_Z, Qmax, alpha, kappa, xi, fs_T, fs_dt, rho );
        X(strat,tickernum,:) = x;
        Q(strat,tickernum,:) = q;
        T(strat,tickernum,:,:) = t;
            
        %%% RUN DSCR
        [ x, q, t ] = cts_backtest_fullyear( data, h_dscr, dm_dscr, dp_dscr, ...
            num_bins, dt_Z, Qmax, alpha, kappa, xi, fs_T, 1, rho );
        X(strat+1,tickernum,:) = x;
        Q(strat+1,tickernum,:) = q;
        T(strat+1,tickernum,:,:) = t;
    end
    toc;
end
save('./saves/outofsample/OOS-annual-INTC.mat', 'X','Q','T');