myfiles = dir('.\data\NTAP*.mat');

rho = [0 : 1/21 : 1]';

mu_b = NaN(length(myfiles), length(rho)-1);
mu_s = NaN(length(myfiles), length(rho)-1);

for i = 1 : length(myfiles)
    
    fprintf(['loading ' myfiles(i).name '\n']);
    load(['.\data\' myfiles(i).name]);
    
    NASDAQ = data;
    
    MO = ExtractMOs(NASDAQ);
    
    [this_mu_b, this_mu_s] = MarketOrderImbalance(rho, MO, NASDAQ);
    
    mu_b(i,:) = this_mu_b';
    mu_s(i,:) = this_mu_s';
    
end