%% Plot a histogram of book value changes over specified intrevals.
% bookvalue - output of the naive trading strategy run
% book_interval - number of time steps to compute over. 
% eg if dt_imb_avg is 800 and we want 15min intervals, then book interval =
% 15 * 60 * 1000 / 800

function plothistobookval(data, bookvalues, book_interval, ticker)

    bookvalues = normalizebookvals(data, bookvalues);
    
    num_intervals = floor(length(bookvalues) / book_interval);
    
    interval_chgs = zeros(num_intervals,1);
    
    for int = 1 : num_intervals
        start = (int-1)*book_interval;
        if start == 0, start = 1; end;
        interval_chgs(int) = bookvalues(int*book_interval) - bookvalues(start);
    end
    
    edge_int = 0.05;
    edge_min = floor(min(interval_chgs)/edge_int)*edge_int;
    edge_max = ceil(max(interval_chgs)/edge_int)*edge_int;
    edge = max(abs(edge_min), edge_max);
    edges = [-edge: edge_int : edge];
    N = histc(interval_chgs, edges);
    fig = bar(edges,N,'histc');
    
    title(sprintf('Naive Trading Strategy - 15min Interval Histogram - %s', ticker));
    xlabel('Chg in Book Val over 15min') % x-axis label
    xlim([-edge, edge]);
    ylabel('# Occurences');
    
    saveas(fig, sprintf('naive_strategy/fig-15minhist-%s.jpg',ticker));