%%% Compare of the naive, naive+, and naive++ strategies for a year.
% For a given ticker, calibrate on 1-day, backtest entire year.
% We have full-year data for: INTC, NTAP, ORCL, SMH

ticker = 'ORCL';
early_close_dates = ['20130703';'20131129';'20131224'];
ib_avg_method = 5;
%[fitnessmat,bin,imb,ds] = runnaivecalibration(data, ib_avg_method);
bin = 5;
imb = 1000;
ds = 1000;

listing = dir(sprintf('data-more/%s*',ticker));

% Calibrate run parameters off the first file.
datafile = sprintf('./data-more/%s',listing(1).name);
load(datafile);
if all(size(data) == [1 1]) == 0, data = data{1,1}; end;

fprintf('Running in-sample backtesting...\n');
reversestr = '';
tic;
    
serieslength = (16-9.5)*3600000/imb;

year_midprices = NaN(numel(listing),serieslength);
npv_naive = NaN(numel(listing),serieslength);
npv_naivep = NaN(numel(listing),serieslength);
npv_naivepp = NaN(numel(listing),serieslength);
inv_naive = NaN(numel(listing),serieslength);
inv_naivep = NaN(numel(listing),serieslength);
inv_naivepp = NaN(numel(listing),serieslength);
numtrades_naive = NaN(numel(listing),1);
numtrades_naivep = NaN(numel(listing),1);
numtrades_naivepp = NaN(numel(listing),1);

msg = sprintf('Estimated time remaining: %d seconds\n', round(toc * (numel(listing)/1 - 1)));
fprintf([reversestr, msg]);
reversestr = repmat('\b', 1, length(msg));

for file = 1 : numel(listing)
    
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
        i = 1;
        while isempty(data{i})
            i = i+1;
        end
        data = data{i};
    end


    [~,inventory,bookvalues,numtrades,midprices] = naivetradingstrategy(data, imb, bin, ds, ticker, 0, early_close, ib_avg_method);
    [bookvalues,normedmidprices] = normalizebookvals(bookvalues,midprices);
    year_midprices(file,1:numel(normedmidprices)) = normedmidprices;
    npv_naive(file,1:numel(bookvalues)) = bookvalues;
    inv_naive(file,1:numel(bookvalues)) = inventory;
    numtrades_naive(file) = numtrades;
    
    [~,inventory,bookvalues,numtrades] = naiveplustradingstrategy(data, imb, bin, ds, ticker, 0, early_close, ib_avg_method);
    [bookvalues,~] = normalizebookvals(bookvalues,midprices);
    npv_naivep(file,1:numel(bookvalues)) = bookvalues;
    inv_naivep(file,1:numel(bookvalues)) = inventory;
    numtrades_naivep(file) = numtrades;
    
    [~,inventory,bookvalues,numtrades] = naiveplusplustradingstrategy(data, imb, bin, ds, ticker, 0, early_close, ib_avg_method);
    [bookvalues,~] = normalizebookvals(bookvalues,midprices);
    npv_naivepp(file,1:numel(bookvalues)) = bookvalues;
    inv_naivepp(file,1:numel(bookvalues)) = inventory;
    numtrades_naivepp(file) = numtrades;
    
    msg = sprintf('Estimated time remaining: %d seconds\n', round(toc * (numel(listing)/file - 1)));
    fprintf([reversestr, msg]);
    reversestr = repmat('\b', 1, length(msg));
    
end

% plot the averages
T1 = 9.5 * 3600000;
T2 = 16 * 3600000;
t = [T1 + imb : imb : T2]; 
plotstep = 20;

avg_naive = nanmean(npv_naive,1);
avg_naive_plus = nanmean(npv_naivep,1);
avg_naive_plus_plus = nanmean(npv_naivepp,1);
avg_mid = nanmean(year_midprices,1) - 1;

f = figure(102);
hold on
curve_mid = plot(1/3600000*t(1:plotstep:end), avg_mid(1:plotstep:end), '-k');
curve_avg_naive = plot(1/3600000*t(1:plotstep:end), avg_naive(1:plotstep:end), '-r');
curve_avg_naive_plus = plot(1/3600000*t(1:plotstep:end), avg_naive_plus(1:plotstep:end), '-b');
curve_avg_naive_plus_plus = plot(1/3600000*t(1:plotstep:end), avg_naive_plus_plus(1:plotstep:end), '-g');
hold off
xlabel('Time (h)') % x-axis label
xlim([9.5 16]);
ylabel('Normalized Book Value') % y-axis label
legend([curve_mid,curve_avg_naive,curve_avg_naive_plus,curve_avg_naive_plus_plus],'Mid','Naive','Naive+','Naive++')
%saveas(f, sprintf('strategy_naive/fig-strategycompare-fixed-%s.jpg',ticker));
matlab2tikz(sprintf('%s-strategy-compare.tikz',ticker));
save(sprintf('%s-strategy-compare.mat',ticker), ...
    'year_midprices','npv_naive','npv_naivep','npv_naivepp',... 
    'inv_naive','inv_naivep','inv_naivepp',...
    'numtrades_naive','numtrades_naivep','numtrades_naivepp');
    