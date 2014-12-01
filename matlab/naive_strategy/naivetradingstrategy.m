function [cash,P_bid,bookvalues] = naivetradingstrategy(data, dt_imbalance_avg, num_bins, dt_price_chg)

    T1 = 9.5 * 3600000;
    T2 = 16 * 3600000;
    t = [T1 + dt_imbalance_avg : dt_imbalance_avg : T2];    % these are the endpoints of avging intervals
    
    time_ctr = find(data.Event(:,1) >= T1, 1, 'first');
    
    opening_mid = (data.BuyPrice(time_ctr,1) + data.SellPrice(time_ctr,1))/20000;
    
    [P_bid, ~, binseries, bidchgseries, ~] = computeprobabilitypricechange(data, dt_imbalance_avg, num_bins, dt_price_chg);
    
    log_name = sprintf('naive_trading_%s.log', datestr(now,'yyyymmdd_HHMMSS'));
    fid = fopen(log_name,'w');
    fprintf(fid, '[timestamp] {imbalance_prev, dS_prev, imbalance_curr}. Buy/Sell price (timestamp). [Asset, Cash]\n');
    
    cash = 0;
    asset = 0;
    bookvalues = zeros(length(t),1);
    
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
            fprintf(fid, '[%d] {%d, %d, %d}. Sell at %.2f (%d). [%d, %.2f].\n', t(timestep), IB_prev, DS_prev, IB_curr, price, price_time, asset, cash);
            
        elseif P_bid(3,B,IB_curr) > 0.5
            % buy asset
            asset = asset + 1;
            price = data.SellPrice(time_ctr,1)/10000;
            price_time = data.Event(time_ctr,1);
            cash = cash - price;
            fprintf(fid, '[%d] {%d, %d, %d}.   Buy at %.2f (%d). [%d, %.2f].\n', t(timestep), IB_prev, DS_prev, IB_curr, price, price_time, asset, cash);
            
        end
        
        bookvalues(timestep) = computebookvalue(data, time_ctr, cash, asset);

    end
    
    % liquidate position at close price.
    if asset > 0
        price = data.BuyPrice(time_ctr,1)/10000;
        price_time = data.Event(time_ctr,1);
        cash = cash + asset * price;
        fprintf(fid, '[%d] Closing long position %d shares at %.2f (%d).\n', t(timestep), asset, price, price_time);
    elseif asset < 0
        price = data.SellPrice(time_ctr,1)/10000;
        price_time = data.Event(time_ctr,1);
        cash = cash + asset * price;
        fprintf(fid, '[%d] Closing short position %d shares at %.2f (%d).\n', t(timestep), asset, price, price_time);
    end
    fprintf(fid, '[%d] Final cash: %.2f.\n', t(timestep), cash);
    fprintf(fid, '[%d] Normalized Final cash: %.2f.\n', t(timestep), cash/opening_mid);
    fclose(fid);
    
    f = figure(1);
    plot(t/3600000, bookvalues);
    title('Naive Trading Strategy')
    xlabel('Time (h)') % x-axis label
    xlim([9.5 16]);
    ylabel('Book Value $$$') % y-axis label
end

function value = computebookvalue(data, time_ctr, cash, asset)
    mid_price = (data.BuyPrice(time_ctr,1) + data.SellPrice(time_ctr,1))/20000;
    value = cash + asset*mid_price;
end
    