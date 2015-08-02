function [mu_b, mu_s] = MarketOrderImbalance(rho, MO, data)

% imbalance at market order events
IB = MO(:,4) ./ (MO(:,4)+MO(:,5));

%imbalance at all events
idx = (data.Event(:,1) >= 9.5*3600000 & data.Event(:,1) <= 16*3600000);
IB_all = sum(data.BuyVolume(idx,1),2) ./ sum(data.BuyVolume(idx,1) + data.SellVolume(idx,1),2);
dt = diff(data.Event(idx,1));

mu_b = zeros(length(rho)-1,1);
mu_s = zeros(length(rho)-1,1);

for k = 1 : length(rho)-1
    
    % imbalance range
    idx_IB = ( IB >= rho(k) & IB < rho(k+1) );
    
    % find total time spent in this IB range
    idx_t = ( IB_all >= rho(k) & IB_all < rho(k+1) );
    timeIn = sum(idx_t(1:end-1) .* dt);
    
    %%% Buy Market Orders %%%
    NumMOEvents = sum(idx_IB & (MO(:,8)==-1));
    mu_b(k) = NumMOEvents/timeIn;
    
    %%% Sell Market Orders %%%
    NumMOEvents = sum(idx_IB & (MO(:,8)==+1));
    mu_s(k) = NumMOEvents/timeIn;
    
end

figure(100);
hold on
midrho = 0.5*(rho([2:end])+rho([1:end-1]));
plot(midrho, mu_b, '-or', midrho, mu_s, '-ob');
