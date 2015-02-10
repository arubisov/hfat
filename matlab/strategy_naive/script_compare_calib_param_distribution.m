%%% Run daily calibration for a given month, look at distribution of
%%% parameters, and compare against having amalgamated all the data into
%%% one.

ticker = 'MMM';

listing = dir(sprintf('data-more/%s_201301*',ticker));

bin = zeros(numel(listing)+1,5);
imb = zeros(numel(listing)+1,5);
ds = zeros(numel(listing)+1,5);

fprintf('Running calibration testing...\n');
reversestr = '';
tic;

for file = 1 : numel(listing)
    
    datafile = sprintf('./data-more/%s',listing(file).name);
    load(datafile);
    if all(size(data) == [1 1]) == 0, data = data{1,1}; end;

    for imb_avg_type = 1:1
        [~,bin(file,imb_avg_type),imb(file,imb_avg_type),ds(file,imb_avg_type)] = runnaivecalibration(data, imb_avg_type);
    end
    
    fprintf('Calibrating for file: %s\n',listing(file).name);
end

% plot the histogram


plothistogram = true;

if plothistogram
    f = figure(103);
    for row = 1:1
        subplot(1,2,(row-1)*2 + 1);
        hist(bin(1:end-1,row)',3:10);
        avg = mean(bin(1:end-1,row));
        stdev = std(bin(1:end-1,row));
        title(sprintf('Imb Calc Mthd %i - Mean %.2f - StdDev %.2f', row, avg, stdev));
        
        subplot(1,2,(row-1)*2 + 2);
        hist(imb(1:end-1,row)',100:100:1000);
        avg = mean(imb(1:end-1,row));
        stdev = std(imb(1:end-1,row));
        title(sprintf('Imb Calc Mthd %i - Mean %.2f - StdDev %.2f', row, avg, stdev));
        
    end
end

save(sprintf('strategy_naive_plus/calib_param_dist_%s.mat',ticker));

% 
% f = figure(102);
% edge_int = 0.05;
% edge_min = floor(min(interval_chgs(:))/edge_int)*edge_int;
% edge_max = ceil(max(interval_chgs(:))/edge_int)*edge_int;
% edge = max(abs(edge_min), edge_max);
% edges = [-edge: edge_int : edge];
% N = histc(interval_chgs(:), edges);
% bar(edges,N,'histc');
% 
% title(sprintf('Naive Trading Strategy - %s Interval Histogram - %s', book_interval, ticker));
% xlabel(sprintf('Chg in Book Val over %s', book_interval)) % x-axis label
% xlim([-edge, edge]);
% ylabel('# Occurences');
% 
% saveas(f, sprintf('strategy_naive/fig-%s-%s-hist%s.jpg',ticker,book_interval,save_comment));
% 
% T1 = 9.5 * 3600000;
% T2 = 16 * 3600000;
% t = [T1 + imb : imb : T2]; 
% 
% avg_naive_1 = nanmean(year_bookvals_naive(:,:,1),1);
% avg_naive_2 = nanmean(year_bookvals_naive(:,:,2),1);
% avg_naive_3 = nanmean(year_bookvals_naive(:,:,3),1);
% avg_naive_4 = nanmean(year_bookvals_naive(:,:,4),1);
% avg_naive_5 = nanmean(year_bookvals_naive(:,:,5),1);
% avg_mid = nanmean(year_midprices,1) - 1;
% 
% f = figure(101);
% hold on
% curve_mid = plot(t/3600000, avg_mid, 'k', 'LineWidth', 5);
% curve_avg_naive_1 = plot(t/3600000, avg_naive_1, 'r', 'LineWidth', 3);
% curve_avg_naive_2 = plot(t/3600000, avg_naive_2, 'b', 'LineWidth', 3);
% curve_avg_naive_3 = plot(t/3600000, avg_naive_3, 'g', 'LineWidth', 3);
% curve_avg_naive_4 = plot(t/3600000, avg_naive_4, 'c', 'LineWidth', 3);
% curve_avg_naive_5 = plot(t/3600000, avg_naive_5, 'm', 'LineWidth', 3);
% hold off
% title(sprintf('Naive Trading Strategies Comparison - %s', ticker));
% xlabel('Time (h)') % x-axis label
% xlim([9.5 16]);
% ylabel('Book Value $$$') % y-axis label
% legend([curve_mid,curve_avg_naive_1,curve_avg_naive_2,curve_avg_naive_3,curve_avg_naive_4,curve_avg_naive_5],'Mid','Mthd1','Mthd2','Mthd3','Mthd4','Mthd5')
% saveas(f, sprintf('strategy_naive/fig-compare-ibmthd-naive-%s.jpg',ticker));