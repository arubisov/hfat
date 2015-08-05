%% Estimate the doubly stochastic Poisson process model parameters from a day's worth of data.
function [G, lambda] = estimatemodelparameters(data, dt, num_bins)
    

    dt_avg = dt;

    [~, mu_IB] = computeavgmidpriceandimbalance(data, dt_avg);

    % create bins for CTMC
%     rho = NaN(num_bins + 1, 1);
%     rho(1) = -1;
%     rho(num_bins + 1) = 1;
%     for bin = 1 : num_bins - 1
%         rho(bin+1) = prctile(mu_IB, bin * 100 / num_bins);
%     end
% %     midrho = 0.5 * (rho(2:end)+rho(1:end-1));
    rho = [-1 : 1/(num_bins/2) : 1]';
    
    [bin_count_CTMC, IB_regime] = histc(mu_IB, rho);

    % estimate generator matrix G for the underlying CTMC of regime switching.
    G = zeros(num_bins);

    % count number of regime switches
    for i = 2 : length(IB_regime)
        if IB_regime(i-1) == IB_regime(i), continue; end;

        G(IB_regime(i-1), IB_regime(i)) = G(IB_regime(i-1), IB_regime(i)) + 1;    
    end

    for bin = 1 : num_bins
        G(bin,:) = G(bin,:) / (bin_count_CTMC(bin) * dt_avg / 1000);
        G(bin,bin) = -sum(G(bin,:));
    end

    % estimate Poisson process intensities

    MO = ExtractMOs(data);
    % column 1: time of event
    % column 8: buy (-1) sell (+1) indicator
    MO = MO(:,[1 8]);
    MO = removeillegaltimes(MO);
    lambda = zeros(2,num_bins);

    % [bin_count_Poisson, MO_regime] = histc(MO(:,1), rho);
    T1 = 9.5 * 3600000;
    % store rounded times in column 3
    MO(:,3) = (floor(MO(:,1)/dt_avg)*dt_avg - T1)/dt_avg + 1;
    % store regime bin number in column 4
    MO(:,4) = IB_regime(MO(:,3));

    for bin = 1 : num_bins
        lambda(1,bin) = sum(MO(:,4) == bin & MO(:,2) == 1);
        lambda(2,bin) = sum(MO(:,4) == bin & MO(:,2) == -1);

        lambda(1,bin) = lambda(1,bin) / (bin_count_CTMC(bin) * dt_avg / 1000);
        lambda(2,bin) = lambda(2,bin) / (bin_count_CTMC(bin) * dt_avg / 1000);
    end
end
