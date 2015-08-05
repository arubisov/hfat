function [ G ] = estimateCTMC2D( series, num_bins, dt_avg )
    % Now we want to model the 2-D data (bin, $chg), so we'll instead
    % reduce it down to 1-D by multiplying. e.g. for 3 bins, we'll have:
    % 1 = bin 1, <0
    % 2 = bin 2, <0
    % 3 = bin 3, <0
    % 4 = bin 1, 0
    % 5 = bin 2, 0
    % 6 = bin 3, 0
    % 7 = bin 1, >0
    % 8 = bin 2, >0
    % 9 = bin 3, >0
    G = zeros(num_bins*3);
    
    % encode the 2d array into one: add 1 to the $chg, changing it from
    % [-1,0,1] to [0,1,2]. Then multiply by the 2x1 matrix [1;3] to get a
    % unique value in range [1,...,9]
    series(:,2) = series(:,2) + 1;
    series = series * [1;num_bins];

    % count number of regime switches
    for i = 2 : length(series)
        if series(i-1,:) == series(i,:), continue; end;

        G(series(i-1), series(i)) = G(series(i-1), series(i)) + 1;    
    end

    for row = 1 : num_bins*3
        total_occur = sum(series==row);
        if total_occur > 0
            G(row,:) = G(row,:) / (total_occur * dt_avg / 1000);
            G(row,row) = -sum(G(row,:));
        else
            G(row,:) = zeros(1,num_bins*3);
        end
    end
end
