%% Called by getbinpricetimeseries in process of estimating generator G

function rho = createbins(num_bins, mu_IB, type)
    switch type
        case 1
            % create even interval bins
            rho = [-1 : 1/(num_bins/2) : 1]';
            rho(1) = -1.1;
        case 2
            % create even distribution bins (by percentiles)
            rho = NaN(num_bins + 1, 1);
            rho(1) = -1.1;
            rho(num_bins + 1) = 1.1;
            for bin = 1 : num_bins - 1
                rho(bin+1) = prctile(mu_IB, bin * 100 / num_bins);
            end
        case 3
            % create even distribution bins (by percentiles) AND symmetric
            % around zero. do this by taking the absolute values of the
            % imbalances, and finding 2x the percentile (draw a sketch to
            % visualize).
            abs_IB = abs(mu_IB);
            rho = NaN(num_bins + 1, 1);
            rho(1) = -1.1;
            rho(num_bins + 1) = 1.1;
            for bin = 1 : ceil((num_bins - 1)/2)
                rho(num_bins + 1 - bin) = prctile(abs_IB, 100 * (1 - bin * 2 / num_bins));
                rho(1 + bin) = -rho(num_bins + 1 - bin);
            end
    end
end