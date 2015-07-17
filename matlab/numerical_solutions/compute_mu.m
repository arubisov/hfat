function [ muplus, muminus ] = compute_mu( data, oneDseries, dt, num_bins )
% Compute rate of arrival of market orders conditional on Markov Chain state. 

    T1 = 9.5 * 3600000;
    
    % estimate Poisson process intensities
    MO = ExtractMOs(data);
    % column 1: time of event
    % column 8: buy (-1) sell (+1) indicator
    MO = MO(:,[1 8]);
    MO = removeillegaltimes(MO);
    % store rounded times in column 3
    MO(:,3) = (floor(MO(:,1)/dt)*dt - T1)/dt + 1;
    
    % store regime bin number in column 4
    MO(:,4) = oneDseries(MO(:,3));
    muplus = zeros(1, num_bins*3);
    muminus = zeros(1, num_bins*3);
    
    for bin_t = 1 : num_bins*3
        muplus(bin_t) = sum(MO(:,4) == bin_t & MO(:,2) == -1);
        muminus(bin_t) = sum(MO(:,4) == bin_t & MO(:,2) == 1);

        % convert to rate (per sec)
        total_occurrences = sum(oneDseries == bin_t);
        muplus(bin_t) = muplus(bin_t) / (total_occurrences * dt / 1000);
        muminus(bin_t) = muminus(bin_t) / (total_occurrences * dt / 1000);
    end    
end