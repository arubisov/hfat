MO = ExtractMOs(data);
IB = ( data.BuyVolume(:,1) - data.SellVolume(:,1) ) ./ ( data.BuyVolume(:,1) + data.SellVolume(:,1) );

T1 = 9.5 * 3600000;
T2 = 16 * 3600000;
dt = 60000; % one minute increments

t = [T1 : dt : T2];

IB_smooth = zeros(length(t),1);

for k = 1 : length(t)-1
    
    idx = ( (data.Event(:,1) >= t(k)) & (data.Event(:,1) < t(k+1)) );
    tau = data.Event(idx,1);
    dtau = diff(tau);
    
    thisIB = IB(idx);
    
    fprintf([num2str(k) ' ' num2str(sum(idx)) '\n' ]);
    
    if sum(idx) > 1
        IB_smooth(k) = sum(dtau .* thisIB(1:end-1)) / dt;
    else
        fprintf('***********\n');
        if k > 1
            IB_smooth(k) = IB_smooth(k-1);
        else
            IB_smooth(k) = NaN;
        end
    end
    
end