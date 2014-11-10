function [mu_mid, mu_IB] = computeavgmidpriceandimbalance(data, dt)

    Mid = ( data.BuyPrice(:,1) + data.SellPrice(:,1) ) ./ 2;
    IB = ( data.BuyVolume(:,1) - data.SellVolume(:,1) ) ./ ( data.BuyVolume(:,1) + data.SellVolume(:,1) );

    T1 = 9.5 * 3600000;
    T2 = 16 * 3600000;

    t = [T1 : dt : T2];

    mu_mid = zeros(length(t)-1,1);
    mu_IB = zeros(length(t)-1,1);
    
    ctr = find(data.Event(:,1) >= T1, 1, 'first');

    for k = 1 : length(t)-1

        % this line is extremely expensive computationally....
        %idx = ( (data.Event(:,1) >= t(k)) & (data.Event(:,1) < t(k+1)) );
        
        % re-writing
        
        ctr_from = ctr;
        
        while data.Event(ctr,1) < t(k+1)
            ctr = ctr+1;
        end
        
        tau = data.Event(ctr_from:ctr,1);
        dtau = diff(tau);

        thisMid = Mid(ctr_from:ctr);
        thisIB = IB(ctr_from:ctr);

        if ctr > ctr_from
            if sum(dtau) > 1
                mu_mid(k) = sum(dtau .* thisMid(1:end-1)) / sum(dtau);
                mu_IB(k) = sum(dtau .* thisIB(1:end-1)) / sum(dtau);
            else
                mu_mid(k) = mean(thisMid);
                mu_IB(k) = mean(thisIB);
            end
        else
            if k > 1
                mu_mid(k) = mu_mid(k-1);
                mu_IB(k) = mu_IB(k-1);
            else
                %mu_mid(k) = NaN;
                %mu_IB(k) = NaN;
                mu_mid(k) = thisMid;
                mu_IB(k) = thisIB;
            end
        end

    end

end