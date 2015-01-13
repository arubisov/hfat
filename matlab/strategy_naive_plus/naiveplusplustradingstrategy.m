function [cash,P_bid,bookvalues] = naiveplusplustradingstrategy(data, dt_imbalance_avg, num_bins, dt_price_chg, ticker, display, early_close)
% Backtest Naive++ Trading Strategy
%   We'll always keep limit orders at the touch. Using the conditional
%   probabilities obtained from the P_bid matrix, if we expect a price
%   change then we'll pull away from the other side. (And hopefully pick up
%   someone stupid enough to execute the wrong way.)

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
        log_name = sprintf('strategy_naive_plus/naive++_trading_%s_%s.log', datestr(now,'yyyymmdd_HHMMSS'),ticker);
        fid = fopen(log_name,'w');
        fprintf(fid, '[timestamp] {imbalance_prev, dS_prev, imbalance_curr}. Buy/Sell price (timestamp). [Asset, Cash]\n');
    end
    
    MO = ExtractMOs(data);
    % column 1: time of event
    % column 8: buy (-1) sell (+1) indicator
    MO = MO(:,[1 8]);
    MO = removeillegaltimes(MO);
    MO(:,3) = match_to_timestep(t,MO(:,1));     % all trades arriving between this timestep and the next.
    MO(:,4) = match_to_timestep(data.Event(:,1),MO(:,1));  % to get most recent mid-price.
    
    cash = 0;
    asset = 0;
    bookvalues = zeros(length(t),1);
    
    LO_buy_posted = 0;
    LO_sell_posted = 0;
    
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
            % price expected to go down. remove the buy LO.
            LO_buy_posted = 0;
            LO_sell_posted = 1;
            
        elseif P_bid(3,B,IB_curr) > 0.5
            % price expected to go up. remove the sell LO.
            LO_buy_posted = 1;
            LO_sell_posted = 0;
            
        elseif P_bid(2,B,IB_curr) > 0.5
            % no price change expected, maintain LOs. 
            LO_buy_posted = 0;
            LO_sell_posted = 0;
        end
        
        % now check all trades arriving between this timestep and the next.
        trades = MO((MO(:,3) == timestep), :);
        for i = 1 : size(trades,1)
            if trades(i,2) == 1 && LO_buy_posted
                % market order sell, so we buy at BID (buy) price
                asset = asset + 1;
                price = data.BuyPrice(trades(i,4),1)/10000;
                price_time = data.Event(trades(i,4),1);
                cash = cash - price;
                if display, fprintf(fid, '[%d] {%d, %d, %d}. MO sell arrived. Buy at %.2f (%d). [%d, %.2f].\n', trades(i,1), IB_prev, DS_prev, IB_curr, price, price_time, asset, cash); end;
            elseif trades(i,2) == -1 && LO_sell_posted
                % market order buy, so we sell at ASK (sell) price
                asset = asset - 1;
                price = data.SellPrice(trades(i,4),1)/10000;
                price_time = data.Event(trades(i,4),1);
                cash = cash + price;
                if display, fprintf(fid, '[%d] {%d, %d, %d}. MO buy arrived. Sell at %.2f (%d). [%d, %.2f].\n',  trades(i,1), IB_prev, DS_prev, IB_curr, price, price_time, asset, cash); end;
            end
        end
        
        bookvalues(timestep) = computebookvalue(data, time_ctr, cash, asset);

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
        title(sprintf('Naive++ Trading Strategy - %s', ticker));
        xlabel('Time (h)') % x-axis label
        xlim([9.5 16]);
        ylabel('Book Value $$$') % y-axis label
        saveas(f, sprintf('strategy_naive_plus/naive++-fig-bookvals-%s.jpg',ticker));
    end
end

function value = computebookvalue(data, time_ctr, cash, asset)
    mid_price = (data.BuyPrice(time_ctr,1) + data.SellPrice(time_ctr,1))/20000;
    value = cash + asset*mid_price;
end

