function [ muplus, muminus ] = compute_mu_annual( data, oneDseries, num_bins )
% Compute rate of arrival of market orders conditional on Markov Chain state. 
    
    muplus = zeros(1, num_bins*3);
    muminus = zeros(1, num_bins*3);
    
    for bin_t = 1 : num_bins*3
        idx = (oneDseries == bin_t);
        muplus(bin_t) = sum(data.MOsum(idx,4));
        muminus(bin_t) = sum(data.MOsum(idx,5));

        % convert to rate (per sec)
        total_occurrences = sum(idx);
        muplus(bin_t) = muplus(bin_t) / total_occurrences;
        muminus(bin_t) = muminus(bin_t) / total_occurrences;
    end    
end