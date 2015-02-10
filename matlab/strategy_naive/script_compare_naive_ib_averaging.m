%%% Compare of the naive, naive+, and naive++ strategies for a year.
% For a given ticker, calibrate on 1-day, backtest entire year.
% We have full-year data for: INTC, NTAP, ORCL, SMH

ticker = 'NTAP';

listing = dir(sprintf('data-more/%s*',ticker));

% Calibrate run parameters off the first file.
datafile = sprintf('./data-more/%s',listing(1).name);
load(datafile);
if all(size(data) == [1 1]) == 0, data = data{1,1}; end;

% bin = zeros(5,1);
% imb = zeros(5,1);
% ds = zeros(5,1);
% for i = 1:5
%     [fitnessmat,bin(i),imb(i),ds(i)] = runnaivecalibration(data, i);
% end 

bin = 5 * ones(5,1);
imb = 1000 * ones(5,1);
ds = 1000 * ones(5,1);
fprintf('Running in-sample backtesting...\n');
reversestr = '';
tic;
    
[cash,~,bookvalues,midprices] = naivetradingstrategy(data, imb(1), bin(1), ds(1), ticker, 0, 0, 1);

[bookvalues,normedmidprices] = normalizebookvals(bookvalues,midprices);

%plothistobookval(data, bookvalues, 15*60*1000/imb, ticker);
% book_interval: eg if dt_imb_avg is 800 and we want 15min intervals, then 
% book interval = 15 * 60 * 1000 / 800
book_interval = 15*60*1000/imb(1);

num_intervals = floor(length(bookvalues) / book_interval);

early_close_dates = ['20130703';'20131129';'20131224'];
year_midprices = NaN(numel(listing),numel(bookvalues));
year_bookvals_naive = NaN(numel(listing),numel(bookvalues),5);

year_midprices(1,1:numel(normedmidprices)) = normedmidprices;
year_bookvals_naive(1,1:numel(bookvalues),1) = bookvalues;

for i = 2:5
    [cash,~,bookvalues,midprices] = naivetradingstrategy(data, imb(i), bin(i), ds(i), ticker, 0, 0, i);
    [bookvalues,~] = normalizebookvals(bookvalues,midprices);
    year_bookvals_naive(1,1:numel(bookvalues),i) = bookvalues;
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
    
    if all(size(data) == [1 1]) == 0, data = data{1,1}; end;

    [~,~,bookvalues,midprices] = naivetradingstrategy(data, imb(1), bin(1), ds(1), ticker, 0, early_close, 1);
    [bookvalues,normedmidprices] = normalizebookvals(bookvalues,midprices);
    year_midprices(file,1:numel(normedmidprices)) = normedmidprices;
    year_bookvals_naive(file,1:numel(bookvalues),1) = bookvalues;
    
    for i = 2:5
        [cash,~,bookvalues,midprices] = naivetradingstrategy(data, imb(i), bin(i), ds(i), ticker, 0, early_close, i);
        [bookvalues,~] = normalizebookvals(bookvalues,midprices);
        year_bookvals_naive(file,1:numel(bookvalues),i) = bookvalues;
    end
    
    msg = sprintf('Estimated time remaining: %d seconds\n', round(toc * (numel(listing)/file - 1)));
    fprintf([reversestr, msg]);
    reversestr = repmat('\b', 1, length(msg));
    
end

% plot the averages

T1 = 9.5 * 3600000;
T2 = 16 * 3600000;
t = [T1 + imb : imb : T2]; 

avg_naive_1 = nanmean(year_bookvals_naive(:,:,1),1);
avg_naive_2 = nanmean(year_bookvals_naive(:,:,2),1);
avg_naive_3 = nanmean(year_bookvals_naive(:,:,3),1);
avg_naive_4 = nanmean(year_bookvals_naive(:,:,4),1);
avg_naive_5 = nanmean(year_bookvals_naive(:,:,5),1);
avg_mid = nanmean(year_midprices,1) - 1;

f = figure(101);
hold on
curve_mid = plot(t/3600000, avg_mid, 'k', 'LineWidth', 5);
curve_avg_naive_1 = plot(t/3600000, avg_naive_1, 'r', 'LineWidth', 3);
curve_avg_naive_2 = plot(t/3600000, avg_naive_2, 'b', 'LineWidth', 3);
curve_avg_naive_3 = plot(t/3600000, avg_naive_3, 'g', 'LineWidth', 3);
curve_avg_naive_4 = plot(t/3600000, avg_naive_4, 'c', 'LineWidth', 3);
curve_avg_naive_5 = plot(t/3600000, avg_naive_5, 'm', 'LineWidth', 3);
hold off
title(sprintf('Naive Trading Strategies Comparison - %s', ticker));
xlabel('Time (h)') % x-axis label
xlim([9.5 16]);
ylabel('Book Value $$$') % y-axis label
legend([curve_mid,curve_avg_naive_1,curve_avg_naive_2,curve_avg_naive_3,curve_avg_naive_4,curve_avg_naive_5],'Mid','Mthd1','Mthd2','Mthd3','Mthd4','Mthd5')
saveas(f, sprintf('strategy_naive/fig-compare-ibmthd-naive-%s.jpg',ticker));