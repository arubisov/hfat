%% Called by getbinpricetimeseries in process of estimating generator G

function [t, mu_IB] = computeavgimbalance(data, dt, avg_method)

    T1 = 9.5 * 3600000;
    T2 = 16 * 3600000;
    t = [T1 + dt : dt : T2];    % these are the endpoints of avging intervals

    mu_IB = zeros(length(t),1);
    
    ctr = find(data.Event(:,1) >= T1, 1, 'first');
    
    switch avg_method
        case num2cell(1:3)
            num = avg_method;
            weights = ones(num,1);
        case num2cell(4:5)
            num = avg_method - 2;
            weights = exp(0.5*[0:-1:-(num-1)])';
    end
       
    IB = (data.BuyVolume(:,1:num) * weights - data.SellVolume(:,1:num) * weights) ./ (data.BuyVolume(:,1:num) * weights + data.SellVolume(:,1:num) * weights);

    

    for k = 1 : length(t)

        ctr_from = ctr;
        
        while data.Event(ctr,1) < t(k)
            ctr = ctr+1;
        end
        
        tau = data.Event(ctr_from:ctr,1);
        dtau = diff(tau);

        thisIB = IB(ctr_from:ctr);

        if ctr > ctr_from
            if sum(dtau) > 1
                mu_IB(k) = sum(dtau .* thisIB(1:end-1)) / sum(dtau);
            else
                mu_IB(k) = mean(thisIB);
            end
        else
            if k > 1
                mu_IB(k) = mu_IB(k-1);
            else
                mu_IB(k) = thisIB;
            end
        end

    end