%%% Plot the conditional dependency of mid-price move on limit order book
%%% imblanace across multiple data files. Plot either in sequence or all at
%%% once depending on flag.

% good sets: INTC_20130109 / 14 / 24

%%% PARAMETERS

movie = false;      % true shows date by date, false shows all at once
dt_avg = 100;      % ms time increment for averaging of IB and mid
dt_mid_diff = 2;    % multiple of dt_avg: time increment for change in mid-price

myfiles = dir('.\data\FARO_2013101*.mat');

rho = [-1 : 1/11 : 1]';
midrho = 0.5 * (rho(2:end)+rho(1:end-1));
    
moves_up = NaN(length(myfiles), length(rho)-1);
moves_down = NaN(length(myfiles), length(rho)-1);
norm_up = NaN(length(myfiles), length(rho)-1);
norm_down = NaN(length(myfiles), length(rho)-1);


for i = 1 : length(myfiles)

    fprintf([num2str(i) '/' num2str(length(myfiles)) ': loading ' myfiles(i).name '\n']);
    load(['.\data\' myfiles(i).name]);

    % calculate avg imbalances and avg mid price
    [mu_mid, mu_IB] = computeavgmidpriceandimbalance(data, dt_avg);

    % calculate moves up and down
    [this_moves_up, this_moves_down] = computeconditionalprobmidpricemoves(data, mu_mid, mu_IB, rho, dt_mid_diff);

    moves_up(i,:) = this_moves_up';
    moves_down(i,:) = this_moves_down';

end

% % normalize number of moves to percentage
% sum_up = sum(moves_up,2);
% sum_down = sum(moves_down,2);
% 
% for k = 1 : size(moves_up,1)
%         norm_up(k,:) = moves_up(k,:)/sum_up(k);
%         norm_down(k,:) = moves_down(k,:)/sum_down(k);
% end

norm_up = moves_up;
norm_down = moves_down;

if movie == true

    for k = 1 : size(norm_up,1)
        f = figure(1);
        clf(f);
        plot(midrho, norm_up(k,:), '-o', midrho, norm_down(k,:), '-s');
        ylim([0 2e-04]);
        %getframe();
        title(sprintf(['Conditional Probability of Mid Price Move given Limit Order Book Imbalance\n' myfiles(k).name]))
        xlabel('Limit Order Book Imbalance by Bucket') % x-axis label
        ylabel('Rate of Events') % y-axis label
        pause(1);
    end

else

    f = figure(1);
    clf(f);
    subplot(1,2,1);
    plot(midrho, norm_up, '-o');
    title(sprintf(['Conditional Probability of Mid Price Move given Limit Order Book Imbalance\n' myfiles(1).name ' through ' myfiles(end).name]))
    xlabel('Limit Order Book Imbalance by Bucket') % x-axis label
    ylim([0 2e-04]);
    ylabel('Rate of Events') % y-axis label

    subplot(1,2,2);
    plot(midrho, norm_down, '-s');
    title(sprintf(['Conditional Probability of Mid Price Move given Limit Order Book Imbalance\n' myfiles(1).name ' through ' myfiles(end).name]))
    xlabel('Limit Order Book Imbalance by Bucket') % x-axis label
    ylim([0 2e-04]);
    ylabel('Rate of Events') % y-axis label
    %legend('Upward Moves in Mid-Price','Downward Moves in Mid-Price')

end