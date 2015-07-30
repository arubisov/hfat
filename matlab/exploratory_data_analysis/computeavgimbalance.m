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
       
        % find first index >= t(k)
        while data.Event(ctr,1) < t(k), ctr = ctr+1; end
        
        % abort if no entries over this interval, same IB val as previous.
        if ctr_from == ctr, mu_IB(k) = mu_IB(k-1); continue; end
        
        % calculate imbalance (done properly!)
        tau = [ t(k) - dt; data.Event(ctr_from:ctr-1,1); t(k)];
        dtau = diff(tau);
        thisIB = IB(ctr_from-1:ctr-1);
        mu_IB(k) = (dtau' * thisIB)/dt;
    end

end
