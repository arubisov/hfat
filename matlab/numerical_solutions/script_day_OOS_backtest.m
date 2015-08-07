% Run a single-day calibration and in-sample backtest.
%
% Master's Thesis
% Date  : 2015.07.29
clear;
clc;

tickers = {'FARO','NTAP','ORCL','INTC'};
strategies = {'Naive','Naive+','Naive++','Cts Stoch Ctrl','Dscr Stoch Ctrl','Cts Stoch Ctrl w NMC','Dscr Stoch Ctrl w NMC'};
daterange = '';

% Parameters
T1 = 9.5 * 3600000; % Start of day
T2 = 16 * 3600000;  % End of day
dt_Z = 1000;        % Markov chain time window (in ms) for averaging.
num_bins = 5;       % Markov chain number of bins.
avg_method = 5;     % Order imbalance calculation method
kappa = 100;        % Fill probability constant, exp(-kappa*delta)
alpha = 0.01;       % Liquidation penalty
%xi = 0.01;          % Half the bid-ask spread
phi = 0;            % Running inventory penalty (0 for continuous Case 1)

% Explicit finite difference scheme setup
Qmax = 20;          % max inventory (+/-)
fs_T = 100;            % time (in s) to compute function. assumes convergence beyond that.
fs_dt = 0.01;          % dt (in s) for first order derivative approximation.

% Early close dates
early_close_dates = [20130703;20131129;20131224];

% Run once to get size of arrays.
listing = dir(sprintf('./data-more/%s_%s*',tickers{1},daterange));

% output variables
% MAJOR TODO: re-write so ALL backtesting can receive pre-defined bins,
% otherwise the bins are re-calibrated illegally. 
year_midprices = NaN(numel(listing),(T2-T1)/dt_Z);

% X - PnL
% Q - Inventory
% T - Number of Trades
X = NaN(numel(strategies), numel(tickers),numel(listing),(T2-T1)/dt_Z);
Q = NaN(numel(strategies), numel(tickers),numel(listing),(T2-T1)/dt_Z);
T = NaN(numel(strategies), numel(tickers),numel(listing));

tic;
for tickernum = 1 : numel(tickers)
    % Initial set-up
    ticker = tickers{tickernum};
    fprintf('RUNNING SINGLE-DAY OUT-OF-SAMPLE BACKTEST on %s\n',ticker);

    % Calibrate run parameters off the first file found in directory.
    listing = dir(sprintf('./data-more/%s_%s*',ticker,daterange));

    for file = 1 : numel(listing)
        datafile = sprintf('./data-more/%s',listing(file).name);
        thisdatestr = sscanf(listing(file).name,sprintf('%s_%s.mat',ticker,'%u'));
        thisdate = datenum(int2str(thisdatestr),'yyyymmdd');
        oosdate = thisdate + 7;
        oosdatestr = datestr(oosdate,'yyyymmdd');
        if exist(sprintf('./data-more/%s_%s.mat',ticker,oosdatestr),'file') == 2
            fprintf('Calib: %d / Test: %s\n',thisdatestr,oosdatestr);
            data = load(datafile);
            data = data.data;
            if all(size(data) == [1 1]) == 0, data = data{1,1}; end;

            % is this an early closure day?
            if any(thisdatestr==early_close_dates), early_close = 1;
            else early_close = 0; end
            
            oosdatafile = sprintf('./data-more/%s_%s.mat',ticker,oosdatestr);
            oosdata = load(oosdatafile);
            oosdata = oosdata.data;
            if all(size(oosdata) == [1 1]) == 0, oosdata = oosdata{1,1}; end;

            % is this an early closure day?
            if any(oosdate==early_close_dates), oos_early_close = 1;
            else oos_early_close = 0; end
            
            % Insert for loop over ds_method = [ 1 2 ]
            parfor strat = 1:numel(strategies)
                [x,q,t] = run_OOS_strategy(strat, data, oosdata, dt_Z, num_bins, ...
                            avg_method, early_close, oos_early_close, phi, kappa, alpha, Qmax, fs_T, fs_dt );
                X(strat,tickernum,file,:) = x;
                Q(strat,tickernum,file,:) = q;
                T(strat,tickernum,file) = t;
            end
        end
    end

end
toc;
save('./saves/outofsample/OOS.mat', 'X','Q','T');