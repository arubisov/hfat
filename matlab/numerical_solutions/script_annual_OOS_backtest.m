% Run annual calibration and out-of-sample backtest.
%
% Master's Thesis
% Date  : 2015.08.11
clear;
clc;

tickers = {'ORCL','INTC'};
strategies = {'Cts Stoch Ctrl','Dscr Stoch Ctrl','Cts Stoch Ctrl w NMC','Dscr Stoch Ctrl w NMC'};
daterange = '';

% Parameters
T1 = 9.5 * 3600000; % Start of day
T2 = 16 * 3600000;  % End of day
T3 = 13 * 3600000;  % Half day
dt_Z = 1000;        % Markov chain time window (in ms) for averaging.
num_bins = 5;       % Markov chain number of bins.
avg_method = 5;     % Order imbalance calculation method
kappa = 100;        % Fill probability constant, exp(-kappa*delta)
alpha = 0.01;       % Liquidation penalty
xi = 0.005;          % Half the bid-ask spread
phi = 0;            % Running inventory penalty (0 for continuous Case 1)

% Explicit finite difference scheme setup
Qmax = 20;          % max inventory (+/-)
fs_T = 100;            % time (in s) to compute function. assumes convergence beyond that.
fs_dt = 0.01;          % dt (in s) for first order derivative approximation.

% Early close dates
early_close_dates = [20130703;20131129;20131224];

% Run once to get size of arrays.
listing = dir(sprintf('./data-more/%s_%s*',tickers{1},daterange));

% Output variables
% X - EOD PnL
% Q - Avg Inventory
% T - Number of Trades
X = NaN(numel(strategies),numel(tickers),numel(listing));
Q = NaN(numel(strategies),numel(tickers),numel(listing));
T = NaN(numel(strategies),numel(tickers),numel(listing),2);

tic;
for tickernum = 1 : numel(tickers)
    % Initial set-up
    ticker = tickers{tickernum};

    data = load(sprintf('./data-more/fullyearconsolidated/%s_2013.mat',ticker));
    data = data.data;
    
    % Calibrate run parameters off the first file found in directory.
    listing = dir(sprintf('./data-more/%s_%s*',ticker,daterange));
    numfiles = length(listing);
    
    for ds_method = [1 2]
        
        % calibrate annual here
        [ binseries, pricechgseries, G, rho ] = compute_G_annual( data, num_bins, ds_method );
        [ oneDseries ] = get1Dseries( binseries, pricechgseries, num_bins );
        [ eta ] = compute_eta( oneDseries, pricechgseries, num_bins );
        [ muplus, muminus ] = compute_mu_annual( data, oneDseries, num_bins );

        % CONTINUOUS TIME
        [ h_cts ] = cts_h_case1( phi, num_bins, Qmax, kappa, alpha, xi, ...
                                      G, eta, muplus, muminus, fs_T, fs_dt  );
        [ dp_cts, dm_cts ] = cts_delta_case1( h_cts, Qmax, kappa, xi );
        
        % DISCRETE TIME
        [ P ] = onestep( G, dt_Z );
        [ h_dscr, dp_dscr, dm_dscr ] = dscr_h( num_bins, Qmax, kappa, alpha, xi, ...
                              P, eta, muplus, muminus, fs_T, dt_Z/1000);
        
        strat = 2*(ds_method-1)+1;
                          
        for file = 1:numel(listing)
            fprintf('%s: Annual Calib / Test: %s\n',ticker,listing(file).name);
            datafile = sprintf('./data-more/%s',listing(file).name);
            thisdatestr = sscanf(listing(file).name,sprintf('%s_%s.mat',ticker,'%u'));

            oosdata = load(datafile);
            oosdata = oosdata.data;
            if all(size(oosdata) == [1 1]) == 0, oosdata = oosdata{1,1}; end;

            % is this an early closure day?
            if any(thisdatestr==early_close_dates), oos_early_close = 1;
            else oos_early_close = 0; end

            %%% RUN CTS
            [ x, q, t ] = cts_backtest( oosdata, h_cts, dm_cts, dp_cts, ...
                           num_bins, avg_method, 1, dt_Z, Qmax, alpha, kappa, xi, fs_T, fs_dt, oos_early_close, rho );
            X(strat,tickernum,file) = x(end);
            Q(strat,tickernum,file) = nanmean(q);
            T(strat,tickernum,file,:) = t;
            if oos_early_close, X(strat,tickernum,file) = x((T3-T1)/dt_Z); end;
            
            %%% RUN DSCR
            [ x, q, t ] = cts_backtest( oosdata, h_dscr, dm_dscr, dp_dscr, ...
                           num_bins, avg_method, 1, dt_Z, Qmax, alpha, kappa, xi, fs_T, dt_Z/1000, oos_early_close, rho );                  
            X(strat+1,tickernum,file) = x(end);
            Q(strat+1,tickernum,file) = nanmean(q);
            T(strat+1,tickernum,file,:) = t;
            if oos_early_close, X(strat,tickernum,file) = x((T3-T1)/dt_Z); end;
        end
    end
    toc;

end
save('./saves/outofsample/annual/IS-annual-ORCL-INTC.mat', 'X','Q','T');