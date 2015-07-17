%% Called by getbinpricetimeseries in process of estimating generator G

function [bidchgseries, askchgseries] = computepricechanges(data, t, dt_price_chg)
    bidchgseries = zeros(length(t)-1,1);
    askchgseries = zeros(length(t)-1,1);
    
    ctr_from = 1;
    
    for k = 1 : length(t)-1
        
        while data.Event(ctr_from,1) < t(k)
            ctr_from = ctr_from + 1;
        end
        
        ctr = ctr_from;
        
        while data.Event(ctr,1) <= t(k) + dt_price_chg
            ctr = ctr+1;
        end
        ctr = ctr-1;

        if ctr > ctr_from
            bidchgseries(k) = data.BuyPrice(ctr,1) - data.BuyPrice(ctr_from,1);
            askchgseries(k) = data.SellPrice(ctr,1) - data.SellPrice(ctr_from,1);
        else
            bidchgseries(k) = 0;
            askchgseries(k) = 0;
        end

    end 