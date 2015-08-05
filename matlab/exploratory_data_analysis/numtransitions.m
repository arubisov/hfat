function [ N ] = numtransitions( series, num_bins )
    N = zeros(num_bins*3);
    
    series(:,2) = series(:,2) + 1;
    series = series * [1;num_bins];

    % count number of regime switches
    for i = 1 : num_bins*3
        for j = 1 : num_bins*3
            N(i,j) = sum(series(1:end-1)==i & series(2:end)==j);
        end
    end
end
