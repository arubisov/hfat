% plot the results for Delta
global T
global dt

x = dt:dt:300;

f = figure('Name','Optimal Liquidation Posting Depth');
hold on;
zero = plot(x,deltastar(:,1,11),'-k');
plot(x,deltastar(:,5,11),'--k');

one = plot(x,deltastar(:,1,12),'-b');
plot(x,deltastar(:,5,12),'--b');

two = plot(x,deltastar(:,1,13),'-r');
plot(x,deltastar(:,5,13),'--r');

three = plot(x,deltastar(:,1,14),'-m');
plot(x,deltastar(:,5,14),'--m');

four = plot(x,deltastar(:,1,15),'-g');
plot(x,deltastar(:,5,15),'--g');

hold off;
set(gca,'fontsize',18);
xlabel('Time', 'FontSize', 24, 'interpreter','latex');
ylabel('Depth $\delta$', 'FontSize', 24, 'interpreter','latex');
leg = legend( [zero, one, two, three, four], ...
        { '$q=0$', '$q=1$', '$q=2$', '$q=3$', '$q=4$' } );
set(leg, 'interpreter','latex','fontsize',16);