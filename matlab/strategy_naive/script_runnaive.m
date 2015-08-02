%%% For a given ticker, calibrate on 1-day, backtest entire year.
% We have full-year data for: INTC, NTAP, ORCL, SMH

ticker = 'ORCL';

listing = dir(sprintf('data-more/%s*',ticker));

% Calibrate run parameters off the first file.
datafile = sprintf('./data-more/%s',listing(1).name);
load(datafile);
if all(size(data) == [1 1]) == 0, data = data{1,1}; end;

[fitnessmat,bin,imb,ds] = runnaivecalibration(data, 1);

fprintf('Running in-sample backtesting...\n');
reversestr = '';
tic;

[~,~,bookvalues,midprices] = naivetradingstrategy(data, imb, bin, ds, ticker, 0, 0);

[bookvalues,midprices] = normalizebookvals(bookvalues,midprices);

%plothistobookval(data, bookvalues, 15*60*1000/imb, ticker);
% book_interval: eg if dt_imb_avg is 800 and we want 15min intervals, then 
% book interval = 15 * 60 * 1000 / 800
book_interval = 15*60*1000/imb;

num_intervals = floor(length(bookvalues) / book_interval);

early_close_dates = ['20130703';'20131129';'20131224'];
interval_chgs = NaN(numel(listing),num_intervals);
year_bookvals = NaN(numel(listing),numel(bookvalues));
year_midprices = NaN(numel(listing),numel(bookvalues));
year_bookvals(1,1:numel(bookvalues)) = bookvalues;
year_midprices(1,1:numel(midprices)) = midprices;

for int = 1 : num_intervals
    start = (int-1)*book_interval;
    if start == 0, start = 1; end;
    interval_chgs(1,int) = bookvalues(int*book_interval) - bookvalues(start);
end

msg = sprintf('Estimated time remaining: %d seconds\n', round(toc * (numel(listing)/1 - 1)));
fprintf([reversestr, msg]);
reversestr = repmat('\b', 1, length(msg));

for file = 2 : numel(listing)
    
    datafile = sprintf('./data-more/%s',listing(file).name);
    load(datafile);

    % is this an early closure day?
    early_close = isempty(strfind(datafile,early_close_dates(1,:))) + isempty(strfind(datafile,early_close_dates(2,:))) + isempty(strfind(datafile,early_close_dates(3,:)));
    if early_close == 3
        early_close = 0;
    else
        early_close = 1;
    end
    
    if all(size(data) == [1 1]) == 0
        if ~isempty(data{1})
            data = data{1};
        else
            data = data{2};
        end
    end

    [~,~,bookvalues,midprices] = naivetradingstrategy(data, imb, bin, ds, ticker, 0, early_close);
    [bookvalues,midprices] = normalizebookvals(bookvalues,midprices);
    year_bookvals(file,1:numel(bookvalues)) = bookvalues;
    year_midprices(file,1:numel(midprices)) = midprices;
    
    num_intervals = floor(length(bookvalues) / book_interval);
    
    for int = 1 : num_intervals
        start = (int-1)*book_interval;
        if start == 0, start = 1; end;
        interval_chgs(file,int) = bookvalues(int*book_interval) - bookvalues(start);
    end

    msg = sprintf('Estimated time remaining: %d seconds\n', round(toc * (numel(listing)/file - 1)));
    fprintf([reversestr, msg]);
    reversestr = repmat('\b', 1, length(msg));
    
end

plotbookval(year_bookvals, year_midprices, imb, ticker, '');

plothistobookval(interval_chgs(interval_chgs ~= 0), '15min', ticker, '');

returnsumdailyret(year_bookvals, year_midprices);
