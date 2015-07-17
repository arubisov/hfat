[ t, IB, dS ] = GetIB(data,10,10,10);

figure;

[haxes,hline1,hline2] = plotyy(t/3600000,IB,t/3600000,dS/1000);
xlim(haxes(1), [0 6.5]);
xlim(haxes(2), [0 6.5]);
ylim(haxes(2), [-3 3]);
title('Order Imbalance and Mid-Price');
xlabel('Time (h) from 0930h');
ylabel(haxes(2), '$ change in mid-price');
ylabel(haxes(1), '% order imbalance');

