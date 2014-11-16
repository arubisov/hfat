function [cash,P_bid] = naivetradingstrategy(data, dt_imbalance_avg, num_bins, dt_price_chg)

    T1 = 9.5 * 3600000;
    T2 = 16 * 3600000;
    t = [T1 + 2*dt_imbalance_avg : dt_imbalance_avg : T2];    % these are the endpoints of avging intervals

    % create bins for CTMC
    rho = [-1 : 1/(num_bins/2) : 1]';
    
    [P_bid, ~, binseries, bidchgseries, ~] = computeprobabilitypricechange(data, dt_imbalance_avg, num_bins, dt_price_chg);
    
    log_name = sprintf('naive_trading_%s.log', datestr(now,'yyyymmdd_HHMMSS'));
    fid = fopen(log_name,'w');
    
    cash = 0;
    asset = 0;
    
    h = waitbar(0,'Backtesting naive trading strategy...');
    
    for timestep = 2 : length(t)
        
        waitbar(timestep / length(t));
        
        % imbalance over last two averaging period
        IB_curr = binseries(timestep);
        IB_prev = binseries(timestep-1);
        % check price change over last price change period
        DS_prev = bidchgseries(timestep-1);
        % now check this entry in the probability matrix. If prob > 0.5,
        % buy/sell/nothing accordingly.
        B = IB_prev + num_bins*(sign(DS_prev)+1);
        
        % make money money make money money money!
        if P_bid(1,B,IB_curr) > 0.5
            % sell asset
            index = find(data.Event(:,1) > t(timestep), 1, 'first') - 1;
            
            asset = asset - 1;
            cash = cash + data.BuyPrice(index,1);
            fprintf(fid, '[%d] IB_p=%d, DS_p=%d, IB_c=%d. Sell asset.\n', t(timestep), IB_prev, DS_prev, IB_curr);
            
        elseif P_bid(3,B,IB_curr) > 0.5
            % buy asset
            index = find(data.Event(:,1) > t(timestep), 1, 'first') - 1;
            
            asset = asset + 1;
            cash = cash - data.SellPrice(index,1);
            fprintf(fid, '[%d] IB_p=%d, DS_p=%d, IB_c=%d. Buy asset.\n', t(timestep), IB_prev, DS_prev, IB_curr);
        end

    end
    
    % liquidate position at close price.
    if asset > 0
        index = find(data.Event(:,1) > t(timestep), 1, 'first') - 1;
        cash = cash + asset * data.BuyPrice(index,1);
        fprintf(fid, '[%d] Liquiding long position %d shares at %d.\n', t(timestep), asset, data.BuyPrice(index,1));
    elseif asset < 0
        index = find(data.Event(:,1) > t(timestep), 1, 'first') - 1;
        cash = cash - asset * data.SellPrice(index,1);  
        fprintf(fid, '[%d] Liquiding short position %d shares at %d.\n', t(timestep), asset, data.SellPrice(index,1));
    end
    fprintf(fid, '[%d] Final cash: %d.\n', t(timestep), cash);
    fclose(fid);
    close(h);
    