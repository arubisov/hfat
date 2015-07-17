%%% test exec time

dt_imbalance_avg = 500;
num_bins = 10;
dt_price_chg = 500;
ticker = 'DUMMY';
display = 0;
early_close = 0;
ib_avg_method = 3;

[cash,P_bid,bookvalues] = naiveplustradingstrategy(data, dt_imbalance_avg, num_bins, dt_price_chg, ticker, display, early_close, ib_avg_method);
% total 15.982s
% computeavgimbalance 3.071s
