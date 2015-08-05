function [ xi ] = compute_xi( data, early_close )
% Compute average half-spread, rounded to nearest cent.

    T1 = 9.5 * 3600000;
    
    if early_close, T2 = 13 * 3600000;
    else            T2 = 16 * 3600000;
    end

    from = find(data.Event(:,1) >= T1, 1, 'first');
    to = find(data.Event(:,1) <= T2, 1, 'last');
    data.Event = data.Event(from:to,:);
    data.SellPrice = data.SellPrice(from:to,:);
    data.BuyPrice = data.BuyPrice(from:to,:);
    
    xi = mean(1/10000 * (data.SellPrice(:,1) - data.BuyPrice(:,1)));
    xi = 1/2 * round(xi*100) / 100;
end