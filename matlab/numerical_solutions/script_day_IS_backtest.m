% Run a single-day calibration and in-sample backtest.
%
% Master's Thesis
% Date  : 2015.07.29

clear;
clc;

T1 = 9.5 * 3600000;
T2 = 16 * 3600000;

% Parameters
dt_Z = 1000;        % Markov chain time window (in ms) for averaging.
num_bins = 5;       % Markov chain number of bins.
avg_method = 5;     % Order imbalance calculation method
ds_method = 1;      % Calibration method ('correct' vs 'incorrect')
kappa = 50;         % Fill probability constant, exp(-kappa*delta)
alpha = 0.01;       % Liquidation penalty
xi = 0.01;          % Half the bid-ask spread
phi = 0;            % Running inventory penalty (0 for continuous Case 1)

% Explicit finite difference scheme setup
Qmax = 20;          % max inventory (+/-)
T = 100;            % time (in s) to compute function. assumes convergence beyond that.
dt = 0.01;          % dt (in s) for first order derivative approximation.

% Initial set-up
ticker = 'ORCL_2013050';
fprintf('RUNNING SINGLE-DAY IN-SAMPLE BACKTEST\n');

% Calibrate run parameters off the first file found in directory.
listing = dir(sprintf('data-more/%s*',ticker));
hist_X = zeros(numel(listing),(T2-T1)/dt_Z);
hist_Q = zeros(numel(listing),(T2-T1)/dt_Z);

for file = 1 : numel(listing)
    datafile = sprintf('./data-more/%s',listing(file).name);
    load(datafile);
    if all(size(data) == [1 1]) == 0, data = data{1,1}; end;

    fprintf('Calibrating %s...\n', datafile);
    [ binseries, pricechgseries, G, ~ ] = ...
        compute_G( data, dt_Z, num_bins, avg_method, ds_method );
    [ oneDseries ] = get1Dseries( binseries, pricechgseries, num_bins );
    [ eta ] = compute_eta( oneDseries, pricechgseries, num_bins );
    [ muplus, muminus ] = compute_mu( data, oneDseries, dt_Z, num_bins );

    fprintf('Solving DPEs and optimal deltas...\n');
    [ h ] = cts_h_case1( phi, num_bins, Qmax, kappa, alpha, xi, ...
                                  G, eta, muplus, muminus, T, dt  );
    [ deltaplus, deltaminus ] = cts_delta_case1( h, Qmax, kappa, xi );

    fprintf('Running in-sample backtesting...\n');
    % Note we must use the 'correct' ds_method = 1.
    [ X, Q ] = cts_backtest( data, h, deltaminus, deltaplus, ...
                   num_bins, avg_method, 1, dt_Z, Qmax, alpha, kappa, xi, T, dt );
    % [ cash, q, hist_X, hist_Q, hist_Sb, hist_Sa, hist_dp, hist_dm, hist_Mb, ...
    %     hist_Ms, hist_Fillb, hist_Fills ] = cts_backtest_single( data, h, ...
    %                 deltaminus, deltaplus, num_bins, avg_method, 1, ...
    %                 dt_Z, Qmax, alpha, kappa, xi, T, dt );           
    % plot_single_backtest(  hist_X, hist_Q, hist_Sb, hist_Sa, hist_dp, hist_dm, hist_Mb, ...
    %     hist_Ms, hist_Fillb, hist_Fills, dt_Z );
    hist_X(file,:) = X;
    hist_Q(file,:) = Q;
end

t = [T1 + dt_Z : dt_Z : T2];
t = t/3600000;
figure();
plot(t,mean(hist_X));
figure();
plot(t,mean(hist_Q));