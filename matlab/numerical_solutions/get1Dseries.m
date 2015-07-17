function [ onedseries ] = get1Dseries( binseries, pricechgseries, num_bins )
%Convert binseries and pricechgseries into a one-dimensional series.
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
    
    % encode the 2d array into one: add 1 to the $chg, changing it from
    % [-1,0,1] to [0,1,2]. Then multiply by the 2x1 matrix [1;3] to get a
    % unique value in range [1,...,9]
    twodseries = [binseries(1:end) sign(pricechgseries)];
    onedseries = twodseries;
    onedseries(:,2) = onedseries(:,2) + 1;
    onedseries = onedseries * [1;num_bins];

end

