%% Compute market order rate of arrivals conditional on current imbalance, previous imbalance, previous price change.
%% This hasn't been tested yet!! Make sure it's calculating correctly. 
function [lambda] = computeconditionalratearrival(data, dt, num_bins, cond_type)
    
    if exist('data','var') == 0
        datafile = './data/FARO_20131016.mat';
        %datafile = './data/ORCL_20130515.mat';
        load(datafile);
        fprintf('Loaded data: %s\n', datafile);
    end
    
    if exist('dt_price_chg','var') == 0
        dt_price_chg = 500;
    end
    
    [~, binseries, bidchgseries, ~, ~, ~] = getbinpricetimeseries(data, dt, num_bins, dt_price_chg);

    % estimate Poisson process intensities
    MO = ExtractMOs(data);
    % column 1: time of event
    % column 8: buy (-1) sell (+1) indicator
    MO = MO(:,[1 8]);
    MO = removeillegaltimes(MO);

    % [bin_count_Poisson, MO_regime] = histc(MO(:,1), rho);
    T1 = 9.5 * 3600000;
    % store rounded times in column 3
    MO(:,3) = (floor(MO(:,1)/dt)*dt - T1)/dt + 1;

    % CONDITIONAL ON: current imbalance.
    if cond_type == 1
        % store regime bin number in column 4
        MO(:,4) = binseries(MO(:,3));
        
        lambda = zeros(2,num_bins);
        for bin_t = 1 : num_bins
            lambda(1,bin_t) = sum(MO(:,4) == bin_t & MO(:,2) == 1);
            lambda(2,bin_t) = sum(MO(:,4) == bin_t & MO(:,2) == -1);

            % convert to rate (per sec)
            total_occurrences = sum(binseries == bin_t);
            lambda(:,bin_t) = lambda(:,bin_t) / (total_occurrences * dt / 1000);
        end    
    end
    
    % CONDITIONAL ON: current imbalance, previous price change.
    if cond_type == 2
        % store regime bin number in column 4
        MO(:,4) = binseries(MO(:,3));
        % store previous price (bid) change in column 5
        MO(:,5) = sign(bidchgseries(max(MO(:,3)-1,1)));
        
        lambda = zeros(2,num_bins,3);
        for bin_t = 1 : num_bins
            for ds = -1 : 1
                lambda(1,bin_t,ds+2) = sum(MO(:,4) == bin_t & MO(:,5) == ds & MO(:,2) == 1);
                lambda(2,bin_t,ds+2) = sum(MO(:,4) == bin_t & MO(:,5) == ds & MO(:,2) == -1);

                total_occurrences = sum((binseries(2:end) == bin_t) .* (sign(bidchgseries) == ds));
                lambda(:,bin_t,ds+2) = lambda(:,bin_t,ds+2) / (total_occurrences * dt / 1000);
            end
        end  
    end
    
    % CONDITIONAL ON: current imbalance, previous imbalance.
    if cond_type == 3
        % store regime bin number in column 4
        MO(:,4) = binseries(MO(:,3));
        % store previous regime bin number in column 5
        MO(:,5) = binseries(max(MO(:,3)-1,1));
        
        lambda = zeros(2,num_bins,num_bins);
        for bin_t = 1 : num_bins
            for bin_t_1 = 1 : num_bins
                lambda(1,bin_t,bin_t_1) = sum(MO(:,4) == bin_t & MO(:,5) == bin_t_1 & MO(:,2) == 1);
                lambda(2,bin_t,bin_t_1) = sum(MO(:,4) == bin_t & MO(:,5) == bin_t_1 & MO(:,2) == -1);

                total_occurrences = sum((binseries(2:end) == bin_t) .* (binseries(1:end-1) == bin_t_1));
                lambda(:,bin_t,bin_t_1) = lambda(:,bin_t,bin_t_1) / (total_occurrences * dt / 1000);
            end
        end  
    end
    
    % CONDITIONAL ON: current imbalance, prev imbalance, prev price change.
    if cond_type == 4
        % store regime bin number in column 4
        MO(:,4) = binseries(MO(:,3));
        % store previous regime bin number in column 5
        MO(:,5) = binseries(max(MO(:,3)-1,1));
        % store previous price (bid) change in column 6
        MO(:,6) = sign(bidchgseries(max(MO(:,3)-1,1)));
        
        lambda = zeros(2,num_bins,num_bins,3);
        roll_sum=0;
        for bin_t = 1 : num_bins
            for bin_t_1 = 1 : num_bins
                for ds = -1 : 1
                    lambda(1,bin_t,bin_t_1,ds+2) = sum(MO(:,4) == bin_t & MO(:,5) == bin_t_1 & MO(:,6) == ds & MO(:,2) == 1);
                    lambda(2,bin_t,bin_t_1,ds+2) = sum(MO(:,4) == bin_t & MO(:,5) == bin_t_1 & MO(:,6) == ds & MO(:,2) == -1);

                    total_occurrences = sum((binseries(2:end) == bin_t) .* (binseries(1:end-1) == bin_t_1) .* (sign(bidchgseries) == ds));
                    %fprintf('bin_cur %d, bin_prev %d, ds %d: %d occurrences.\n',bin_t, bin_t_1, ds, total_occurrences);
                    lambda(:,bin_t,bin_t_1,ds+2) = lambda(:,bin_t,bin_t_1,ds+2) / (total_occurrences * dt / 1000);
                end
            end
        end  
    end
    
end