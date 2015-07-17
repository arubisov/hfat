%% Get volume imbalance from a day's worth of data, average, and transform into a timeseries of bins
% data          data to run against
% dt            time increment over which to average imbalances
% num_bins      number of bins to cast the imbalances into
function [t, binseries] = getbintimeseries(data, dt, num_bins)
    
    if exist('data','var') == 0
        load('./data/ORCL_20130515.mat');
       % load('./data/FARO_20131016.mat');
    end

    if exist('dt','var') == 0
        dt = 1000;
    end
    
    if exist('num_bins','var') == 0
        num_bins = 3;
    end
   
    [~, mu_IB] = computeavgmidpriceandimbalance(data, dt);
    
    T1 = 9.5 * 3600000;
    T2 = 16 * 3600000;
    t = [T1 : dt : T2 - dt];

    % create bins for CTMC
    rho = [-1 : 1/(num_bins/2) : 1]';

    [bin_count, IB_regime] = histc(mu_IB, rho);
    
    binseries = IB_regime;
    
end