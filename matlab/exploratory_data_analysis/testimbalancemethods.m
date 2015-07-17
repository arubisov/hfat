

T1 = 9.5 * 3600000;
T2 = 16 * 3600000;
t = [T1 + 500 : 500 : T2];    % these are the endpoints of avging intervals

mu_IB = zeros(length(t),1);

t_start = find(data.Event(:,1) >= T1, 1, 'first');
t_end = find(data.Event(:,1) >= T2, 1, 'first');



%%% method 1
num = 1;
IB1 = ( sum(data.BuyVolume(t_start:t_end,1:num),2) - sum(data.SellVolume(t_start:t_end,1:num),2) ) ./ ( sum(data.BuyVolume(t_start:t_end,1:num),2) + sum(data.SellVolume(t_start:t_end,1:num),2) );

%%% method 2
num = 2;
IB2 = ( sum(data.BuyVolume(t_start:t_end,1:num),2) - sum(data.SellVolume(t_start:t_end,1:num),2) ) ./ ( sum(data.BuyVolume(t_start:t_end,1:num),2) + sum(data.SellVolume(t_start:t_end,1:num),2) );

%%% method 3
num = 3;
weights = ones(num,1);
IB6 = (data.BuyVolume(t_start:t_end,1:num) * weights - data.SellVolume(t_start:t_end,1:num) * weights) ./ (data.BuyVolume(t_start:t_end,1:num) * weights + data.SellVolume(t_start:t_end,1:num) * weights);

%%% method 4 - wtd sum of 2
num = 2;
weights = exp(0.5*[0:-1:-(num-1)])';
IB4 = (data.BuyVolume(t_start:t_end,1:num) * weights - data.SellVolume(t_start:t_end,1:num) * weights) ./ (data.BuyVolume(t_start:t_end,1:num) * weights + data.SellVolume(t_start:t_end,1:num) * weights);

%%% method 5 - wtd sum of 3
num = 3;
weights = exp(0.5*[0:-1:-(num-1)])';
IB5 = (data.BuyVolume(t_start:t_end,1:num) * weights - data.SellVolume(t_start:t_end,1:num) * weights) ./ (data.BuyVolume(t_start:t_end,1:num) * weights + data.SellVolume(t_start:t_end,1:num) * weights);


g = figure('Name','Estimated Parameters for Lambda');
subplot(2,3,1);
plot(IB1);
title('IB1');
subplot(2,3,2);
plot(IB2);
title('IB2');
subplot(2,3,3);
plot(IB3);
title('IB3');
subplot(2,3,4);
plot(IB4);
title('IB4');
subplot(2,3,5);
plot(IB5);
title('IB5');