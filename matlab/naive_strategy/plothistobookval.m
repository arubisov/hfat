%% Plot a histogram of book value changes over specified intrevals.
% bookvalue - output of the naive trading strategy run
% book_interval - number of time steps to compute over. 
% eg if dt_imb_avg is 800 and we want 15min intervals, then book interval =
% 15 * 60 * 1000 / 800

function plothistobookval(bookvalues, book_interval)

    bookvalues = normalizebookvals(data, bookvalues);
    
    num_intervals = floor(length(bookvalues) / book_interval);
    
    interval_chgs = zeros(num_intervals,1);
    
    for int = 1 : num_intervals
        start = (int-1)*book_interval;
        if start == 0, start = 1; end;
        interval_chgs(int) = bookvalues(int*book_interval) - bookvalues(start);
    end
    
    edges = [-0.4 : 0.05 : 0.4];
    N = histc(interval_chgs, edges);
    bar(edges,N,'histc');
