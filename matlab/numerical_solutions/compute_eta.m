function [ eta_table ] = compute_eta( oneDseries, pricechgseries, num_bins )
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here
    rows = min(pricechgseries):100:max(pricechgseries);
    eta_table = zeros(length(rows),num_bins*3);
    
    for z = 1:num_bins*3
        for row = 1:length(rows)
            eta_table(row,z+1) = sum(oneDseries == z & pricechgseries == rows(row));
        end
    end
    
    eta_table(:,2:end) = eta_table(:,2:end)./repmat(sum(eta_table(:,2:end),1),length(rows),1);
    eta_table(:,1) = 1/10000 * rows';
end