%%% Show mid price and LOB imbalance by buckets. Checking predictive power
%%% of the imbalanced LOB, whether it dictates where the mid will be
%%% moving.

rho = [-1 : 1/11 : 1]';

% imbalance at all events
idx = (data.Event(:,1) >= 9.5*3600000 & data.Event(:,1) <= 16*3600000);
IB_all = ( data.BuyVolume(idx,1) - data.SellVolume(idx,1) ) ./ ( data.BuyVolume(idx,1) + data.SellVolume(idx,1) );
dt = diff(data.Event(idx,1));

% change in mid price - time increment is the averaging period
deltaMid = diff(mu_mid);

for k = 1 : length(rho)-1
    
    % imbalance range
    if k < length(rho)-1
        idx_IB = ( mu_IB >= rho(k) & mu_IB < rho(k+1) );
        idx_t = ( IB_all >= rho(k) & IB_all < rho(k+1) );
    else
        idx_IB = ( mu_IB >= rho(k) & mu_IB <= rho(k+1) );
        idx_t = ( IB_all >= rho(k) & IB_all <= rho(k+1) );
    end
    
    % find total time spent in this IB range
    timeIn = sum(idx_t(1:end-1) .* dt);
    
    % Number of times mid price moves upward %
    numMoves = sum(idx_IB(1:end-1) & (deltaMid(:,1) > 0));
    moves_up(k) = numMoves %/timeIn;
    
    % Number of times mid price moves downward %
    numMoves = sum(idx_IB(1:end-1) & (deltaMid(:,1) < 0));
    moves_down(k) = numMoves %/timeIn;
    
    % Number of no-change %
    numMoves = sum(idx_IB(1:end-1) & (deltaMid(:,1) == 0));
    moves_nochg(k) = numMoves %/timeIn;
    
end

% plot(midrho, moves_up, '-or', midrho, moves_down, '-ob');

midrho = 0.5*(rho(2:end)+rho(1:end-1));
    
figure(100);
bar(midrho,[moves_up', moves_down', moves_nochg'])
title('Conditional Probability of Mid Price Move given Limit Order Book Imbalance')
xlabel('Limit Order Book Imbalance by Bucket') % x-axis label
ylabel('Number of Events') % y-axis label
legend('Upward Moves in Mid-Price','Downward Moves in Mid-Price','No Change in Mid-Price')