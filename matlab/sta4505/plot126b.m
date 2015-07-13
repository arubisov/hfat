% plot the inventory simulation results. 
global T
global dt

x = dt:dt:T;

plotstep = 20;

f = figure('Name','Optimal Liquidation Simulated Inventory');

hold on;
meanplot = plot(x(1:plotstep:end),mean(hist_Q(:,1:plotstep:end)),'-k');
medianplot = plot(x(1:plotstep:end),median(hist_Q(:,1:plotstep:end)),'-b');
fifthqt = plot(x(1:plotstep:end),prctile(hist_Q(:,1:plotstep:end),5),'-r');
ninetyfifthqt = plot(x(1:plotstep:end),prctile(hist_Q(:,1:plotstep:end),95),'-m');
hold off;

set(gca,'fontsize',18);
xlabel('Time', 'FontSize', 24, 'interpreter','latex');
ylabel('Inventory', 'FontSize', 24, 'interpreter','latex');
leg = legend( [meanplot, medianplot, fifthqt, ninetyfifthqt ], ...
        { 'mean', 'median', '5\% quantile', '95\% quantile' } );
set(leg, 'interpreter','latex','fontsize',16);