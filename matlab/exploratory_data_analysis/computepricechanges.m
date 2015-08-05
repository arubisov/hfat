%% Called by getbinpricetimeseries in process of estimating generator G

function [pricechgseries] = computepricechanges(data, t, dt_price_chg)
    pricechgseries = zeros(length(t)-1,1);
    
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
            from_mean = (data.BuyPrice(ctr_from,1)+data.SellPrice(ctr_from,1))/2;
            to_mean = (data.BuyPrice(ctr,1)+data.SellPrice(ctr,1))/2;
            pricechgseries(k) = to_mean - from_mean;
        else
            pricechgseries(k) = 0;
        end
    end 