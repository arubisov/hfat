function [ eta ] = compute_eta( oneDseries, pricechgseries, num_bins )
% Compute expected price change conditional on being in a given Markov chain state.
    eta = zeros(num_bins*3,1);
    
    for z = 1:num_bins*3
        eta(z) = sum(1/10000 * pricechgseries(oneDseries == z));
        eta(z) = eta(z) / sum(oneDseries == z);
    end
end