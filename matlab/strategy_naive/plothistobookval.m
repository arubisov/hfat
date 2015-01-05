%% Plot a histogram of book value changes over specified intrevals.
% interval_chgs - returns that we want to plot
% book_interval - e.g. '15min', title for plot
% ticker        - e.g. 'FARO', title for plot
% save_comment  - any additional comment for filename to save.

function plothistobookval(interval_chgs, book_interval, ticker, save_comment)
   
    f = figure(102);
    edge_int = 0.05;
    edge_min = floor(min(interval_chgs(:))/edge_int)*edge_int;
    edge_max = ceil(max(interval_chgs(:))/edge_int)*edge_int;
    edge = max(abs(edge_min), edge_max);
    edges = [-edge: edge_int : edge];
    N = histc(interval_chgs(:), edges);
    bar(edges,N,'histc');
    
    title(sprintf('Naive Trading Strategy - %s Interval Histogram - %s', book_interval, ticker));
    xlabel(sprintf('Chg in Book Val over %s', book_interval)) % x-axis label
    xlim([-edge, edge]);
    ylabel('# Occurences');
    
    saveas(f, sprintf('strategy_naive/fig-%s-%s-hist%s.jpg',ticker,book_interval,save_comment));