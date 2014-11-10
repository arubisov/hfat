fprintf('Loading defaults...');
datafile = './data/ORCL_20130515.mat';
load(datafile);
num_bins = 3;       % number of bins for underlying CTMC 
dt = 1000;          % ms time increment for averaging of IB and mid
dt_price_chg = 500; % ms time increment for price differences
fprintf('done.\n');