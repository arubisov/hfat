avg_vals = zeros(1,10);
for ctr = 1 : 1
    dt_imbalance_avg = 700;
    num_bins = 9;
    dt_price_chg = 100*ctr;
    [P_bid, ~] = computeprobabilitypricechange(data, dt_imbalance_avg, num_bins, dt_price_chg);

    output = '';
    output_mat = zeros(1,num_bins);
    for i = 1 : num_bins
        output = strcat(output, num2str(P_bid(1, i, i)), ', ');
        output_mat(1,i) = P_bid(1, i, i);
    end
    output = output(1:end-1);
    fprintf('Running dt_imbalance_avg=%d, num_bins=%d, dt_price_chg=%d\n', dt_imbalance_avg, num_bins, dt_price_chg);
    disp(output);
    fprintf('Average probability=%.4f\n', mean(output_mat))
    
    avg_vals(1, ctr) = mean(output_mat);
end
disp(transpose(avg_vals));