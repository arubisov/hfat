% calibrate for a ticker

ticker = 'MMM';
datafile = sprintf('./data/%s_20130515.mat', ticker);
load(datafile);

if all(size(data) == [1 1]) == 0
   data = data{1,1}; 
end


[fitnessmat,bin,imb,ds] = runnaivecalibration(data);

[cash,P_bid,bookvalues] = naivetradingstrategy(data, imb, bin, ds, ticker);

plothistobookval(data, bookvalues, 15*60*1000/imb, ticker);