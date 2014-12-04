function [cash] = naivetradingstrategy_bad(data, dt_imbalance_avg, num_bins, dt_price_chg)

    T1 = 9.5 * 3600000;
    T2 = 16 * 3600000;
    T2 = 34640000;
    dt = 50;                    % trading strategy: check every 50ms
    t = [T1 + 2*dt_imbalance_avg : dt : T2];    % these are the endpoints of avging intervals

    % create bins for CTMC
    rho = [-1 : 1/(num_bins/2) : 1]';
    
    [P_bid, ~] = computeprobabilitypricechange(data, dt_imbalance_avg, num_bins, dt_price_chg);
    
    log_name = sprintf('naive_trading_%s.log', datestr(now,'yyyymmdd_HHMMSS'));
    fid = fopen(log_name,'w');
    
    cash = 0;
    asset = 0;
    
    h = waitbar(0,'Backtesting naive trading strategy...');
    
    for timestep = t
        waitbar((timestep-T1) / (T2-T1));
        
        % compute imbalance over last two averaging period
        IB_curr = computeIB(data, timestep, dt_imbalance_avg);
        [~, IB_curr] = histc(IB_curr, rho);
        IB_prev = computeIB(data, timestep-dt_imbalance_avg, dt_imbalance_avg);
        [~, IB_prev] = histc(IB_prev, rho);
        % check price change over last price change period
        DS_prev = computeDS(data,timestep-dt_imbalance_avg, dt_price_chg);
        % now check this entry in the probability matrix. If prob > 0.5,
        % buy/sell/nothing accordingly.
        B = IB_prev + num_bins*(sign(DS_prev)+1);
        
        % make money money make money money money!
        if P_bid(1,B,IB_curr) > 0.5
            % sell asset
            index = find(data.Event(:,1) > timestep, 1, 'first') - 1;
            
            asset = asset - 1;
            cash = cash + data.BuyPrice(index,1);
            fprintf(fid, '[%d] IB_p=%d, DS_p=%d, IB_c=%d. Sell asset.\n', timestep, IB_prev, DS_prev, IB_curr);
            
        elseif P_bid(3,B,IB_curr) > 0.5
            % buy asset
            index = find(data.Event(:,1) > timestep, 1, 'first') - 1;
            
            asset = asset + 1;
            cash = cash - data.SellPrice(index,1);
            fprintf(fid, '[%d] IB_p=%d, DS_p=%d, IB_c=%d. Buy asset.\n', timestep, IB_prev, DS_prev, IB_curr);
        end

    end
    
    % liquidate position at close price.
    if asset > 0
        index = find(data.Event(:,1) > timestep, 1, 'first') - 1;
        cash = cash + asset * data.BuyPrice(index,1);
        fprintf(fid, '[%d] Liquiding long position %d shares at %d.\n', timestep, asset, data.BuyPrice(index,1));
    elseif asset < 0
        index = find(data.Event(:,1) > timestep, 1, 'first') - 1;
        cash = cash - asset * data.SellPrice(index,1);  
        fprintf(fid, '[%d] Liquiding short position %d shares at %d.\n', timestep, asset, data.SellPrice(index,1));
    end
    fprintf(fid, '[%d] Final cash: %d.\n', timestep, cash);
    fclose(fid);
    close(h);


function imbalance = computeIB(data, timestep, dt_imbalance_avg)
    IB = ( data.BuyVolume(:,1) - data.SellVolume(:,1) ) ./ ( data.BuyVolume(:,1) + data.SellVolume(:,1) );
  
    ctr = find(data.Event(:,1) > timestep, 1, 'first') - 1;
    ctr_from = ctr;

    while data.Event(ctr_from,1) >= timestep - dt_imbalance_avg
        ctr_from = ctr_from-1;
    end
    ctr_from = ctr_from+1;

    tau = data.Event(ctr_from:ctr,1);
    dtau = diff(tau);

    thisIB = IB(ctr_from:ctr);

    if ctr > ctr_from
        if sum(dtau) > 1
            imbalance = sum(dtau .* thisIB(1:end-1)) / sum(dtau);
        else
            imbalance = mean(thisIB);
        end
    else
        imbalance = thisIB;
    end


function pricechange = computeDS(data, timestep, dt_price_chg)
    ctr = find(data.Event(:,1) > timestep, 1, 'first') - 1;
    ctr_from = ctr;
    
    while data.Event(ctr_from,1) < timestep
        ctr_from = ctr_from + 1;
    end

    ctr = ctr_from;

    while data.Event(ctr,1) <= timestep + dt_price_chg
        ctr = ctr+1;
    end
    ctr = ctr-1;

    if ctr > ctr_from
        pricechange = data.BuyPrice(ctr,1) - data.BuyPrice(ctr_from,1);
    else
        pricechange = 0;
    end

    