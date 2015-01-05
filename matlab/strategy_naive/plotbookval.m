%% Plot book values.
% interval_chgs - returns that we want to plot
% book_interval - e.g. '15min', title for plot
% ticker        - e.g. 'FARO', title for plot
% save_comment  - any additional comment for filename to save.

function plotbookval(bookvalues, midprices, imb_int, ticker, save_comment)

    T1 = 9.5 * 3600000;
    T2 = 16 * 3600000;
    t = [T1 + imb_int : imb_int : T2]; 
    
    avg_val = nanmean(bookvalues,1);
    avg_mid = nanmean(midprices,1) - 1;
    
    f = figure(101);
    plot(t/3600000, bookvalues);
    hold on
    curve_avg = plot(t/3600000, avg_val, 'r', 'LineWidth', 5);
    curve_mid = plot(t/3600000, avg_mid, 'k', 'LineWidth', 5);
    hold off
    title(sprintf('Naive Trading Strategy - %s', ticker));
    xlabel('Time (h)') % x-axis label
    xlim([9.5 16]);
    ylabel('Book Value $$$') % y-axis label
    legend([curve_avg,curve_mid],'Average Book Value','Avg Mid Price')
    saveas(f, sprintf('strategy_naive/fig-%s-year-bookvals%s.jpg',ticker,save_comment));