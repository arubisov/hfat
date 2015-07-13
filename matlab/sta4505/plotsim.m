function [ ] = plotsim(  hist_Q, hist_Z, hist_S, hist_d, hist_Mb, hist_Ms, hist_Filled )
% STA4505 Course Project - Ch12 on Order Imbalance
% Plotting the simulation results; replicate Figure 12.7
global T
global dt

t = dt:dt:T;

figure();
hold on
plt_mid = plot(t, hist_S(1,:),'-k','linewidth',3 );
plt_depth = plot(t, hist_S(1,:) + hist_d(1,:),'-g','linewidth',1.5);

iMOb = ~isnan(hist_Mb(1,:)) & ~isnan(hist_Filled(1,:));
tMOb = t(iMOb);
SMOb = hist_S(1,iMOb);
SdMOb = hist_Mb(1,iMOb);
for k = 1 : length(tMOb)
    plot(tMOb(k) * [1 1] , [SMOb(k) SdMOb(k)], '-b', 'linewidth', 1 );
    plt_b_fill = plot(tMOb(k) , SdMOb(k), '-ob', 'markerfacecolor','b', 'linewidth', 1  );
end


iMOb = ~isnan(hist_Mb(1,:)) & isnan(hist_Filled(1,:));
tMOb = t(iMOb);
SMOb = hist_S(1,iMOb);
SdMOb = hist_Mb(1,iMOb);
for k = 1 : length(tMOb)
    plot(tMOb(k) * [1 1] , [SMOb(k) SdMOb(k)], '-b', 'linewidth', 1  );
    plt_b_nofill = plot(tMOb(k) , SdMOb(k), '-ob', 'linewidth', 1  );
end


iMOs = ~isnan(hist_Ms(1,:));
tMOs = t(iMOs);
SMOs = hist_S(1,iMOs);
SdMOs = hist_Ms(1,iMOs);
for k = 1 : length(tMOs)
    plot(tMOs(k) * [1 1] , [SMOs(k) SdMOs(k)], '-r', 'linewidth', 1  );
    plt_s = plot(tMOs(k) , SdMOs(k), '-or', 'linewidth', 1  );
end
hold off
xlabel('Time', 'FontSize', 24, 'interpreter','latex');
ylabel('Price', 'FontSize', 24, 'interpreter','latex');

set(gca,'fontsize',18);
leg = legend( [plt_mid, plt_depth, plt_b_fill, plt_b_nofill, plt_s], ...
        { '$S$', '$S+\delta$', 'MO lifts offer', 'other buy MO', 'sell MO' } );
set(leg, 'interpreter','latex','fontsize',16);

figure();
plot(t,hist_Q(1,:));
xlabel('Time', 'FontSize', 24, 'interpreter','latex');
ylabel('Inventory', 'FontSize', 24, 'interpreter','latex');

figure();
plot(t,hist_d(1,:));
xlabel('Time', 'FontSize', 24, 'interpreter','latex');
ylabel('Delta $\delta$', 'FontSize', 24, 'interpreter','latex');

figure();
plot(t,hist_Z(1,:));
xlabel('Time', 'FontSize', 24, 'interpreter','latex');
ylabel('Imbalance', 'FontSize', 24, 'interpreter','latex');

end

