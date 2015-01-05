function [cash,P_bid,bookvalues,midprices] = naivetradingstrategy(data, dt_imbalance_avg, num_bins, dt_price_chg, ticker, display, early_close)
% Backtest Naive Trading Strategy
%   Using the conditional probabilities obtained from the P_bid matrix,
%   execute a buy/sell market order if the probability of a price change in
%   the right direction is > 0.5

    T1 = 9.5 * 3600000;
    
    if early_close
        T2 = 13 * 3600000;
    else
        T2 = 16 * 3600000;
    end
    
    t = [T1 + dt_imbalance_avg : dt_imbalance_avg : T2];    % these are the endpoints of avging intervals
    
    time_ctr = find(data.Event(:,1) >= T1, 1, 'first');
    
    opening_mid = (data.BuyPrice(time_ctr,1) + data.SellPrice(time_ctr,1))/20000;
    
    [P_bid, ~, binseries, bidchgseries, ~] = computeprobabilitypricechange(data, dt_imbalance_avg, num_bins, dt_price_chg);
    
    if display
        log_name = sprintf('naive_strategy/naive_trading_%s.log', datestr(now,'yyyymmdd_HHMMSS'));
        fid = fopen(log_name,'w');
        fprintf(fid, '[timestamp] {imbalance_prev, dS_prev, imbalance_curr}. Buy/Sell price (timestamp). [Asset, Cash]\n');
    end
    
    cash = 0;
    asset = 0;
    bookvalues = zeros(length(t),1);
    midprices = zeros(length(t),1);
    midprices(1) = opening_mid;
    
    for timestep = 2 : length(t)
        
        % imbalance over last two averaging period
        IB_curr = binseries(timestep);
        IB_prev = binseries(timestep-1);
        % check price change over last price change period
        DS_prev = bidchgseries(timestep-1);
        % now check this entry in the probability matrix. If prob > 0.5,
        % buy/sell/nothing accordingly.
        B = IB_prev + num_bins*(sign(DS_prev)+1);

        while data.Event(time_ctr,1) <= t(timestep)
            time_ctr = time_ctr+1;
        end
        time_ctr = time_ctr-1;
        
        
        if P_bid(1,B,IB_curr) > 0.5
            % sell asset            
            asset = asset - 1;
            price = data.BuyPrice(time_ctr,1)/10000;
            price_time = data.Event(time_ctr,1);
            cash = cash + price;
            if display, fprintf(fid, '[%d] {%d, %d, %d}. Sell at %.2f (%d). [%d, %.2f].\n', t(timestep), IB_prev, DS_prev, IB_curr, price, price_time, asset, cash); end;
            
        elseif P_bid(3,B,IB_curr) > 0.5
            % buy asset
            asset = asset + 1;
            price = data.SellPrice(time_ctr,1)/10000;
            price_time = data.Event(time_ctr,1);
            cash = cash - price;
            if display, fprintf(fid, '[%d] {%d, %d, %d}.   Buy at %.2f (%d). [%d, %.2f].\n', t(timestep), IB_prev, DS_prev, IB_curr, price, price_time, asset, cash); end;
            
        end
        
        mid_price = (data.BuyPrice(time_ctr,1) + data.SellPrice(time_ctr,1))/20000;
        bookvalues(timestep) = cash + asset*mid_price;
        midprices(timestep) = mid_price;

    end
    
    % liquidate position at close price.
    if asset > 0
        price = data.BuyPrice(time_ctr,1)/10000;
        price_time = data.Event(time_ctr,1);
        cash = cash + asset * price;
        if display, fprintf(fid, '[%d] Closing long position %d shares at %.2f (%d).\n', t(timestep), asset, price, price_time); end;
    elseif asset < 0
        price = data.SellPrice(time_ctr,1)/10000;
        price_time = data.Event(time_ctr,1);
        cash = cash + asset * price;
        if display, fprintf(fid, '[%d] Closing short position %d shares at %.2f (%d).\n', t(timestep), asset, price, price_time); end;
    end
    
    if display
        fprintf(fid, '[%d] Final cash: %.2f.\n', t(timestep), cash);
        fprintf(fid, '[%d] Normalized Final cash: %.2f.\n', t(timestep), cash/opening_mid);
        fclose(fid);

        f = figure(1);
        plot(t/3600000, bookvalues);
        title(sprintf('Naive Trading Strategy - %s', ticker));
        xlabel('Time (h)') % x-axis label
        xlim([9.5 16]);
        ylabel('Book Value $$$') % y-axis label
        saveas(f, sprintf('naive_strategy/fig-bookvals-%s.jpg',ticker));
    end
end