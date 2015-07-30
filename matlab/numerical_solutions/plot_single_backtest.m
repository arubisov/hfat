function [ ] = plot_single_backtest(  hist_X, hist_Q, hist_Sb, hist_Sa, hist_dp, hist_dm, hist_Mb, ...
    hist_Ms, hist_Fillb, hist_Fills, dt )
% Mimic simulation plot from STA4505 Ch12, Figure 12.7
%
% Master's Thesis
% Date  : 2015.07.29

T1 = 9.5 * 3600000;
T2 = 16 * 3600000;

% x axis for everything except hist_S, which has its own in first column.
t = [T1 + dt:dt:T2];
t = t/3600000;

hist_S = (hist_Sb+hist_Sa)/2;

figure();
hold on
plt_mid = plot(t, hist_S,'-k','linewidth',3 );
plt_dp = plot(t, hist_Sa + hist_dp,'-g','linewidth',1.5);
plt_dm = plot(t, hist_Sb - hist_dm,'-g','linewidth',1.5);

% Buy MOs that lift our sell LO
iMOb = ~isnan(hist_Mb) & ~isnan(hist_Fills);
tMOb = t(iMOb);
SMOb = hist_S(iMOb);
SdMOb = hist_Sb(iMOb) - hist_dm(iMOb);
for k = 1 : length(tMOb)
    plot(tMOb(k) * [1 1], [SMOb(k) SdMOb(k)], '-b', 'linewidth', 1 );
    plt_b_fill = plot(tMOb(k) , SdMOb(k), '-ob', 'markerfacecolor','b', 'linewidth', 1  );
end

% Buy MOs that do not lift our sell LO
iMOb = ~isnan(hist_Mb(1,:)) & isnan(hist_Fills(1,:));
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
leg = legend( [plt_mid, plt_dp, plt_dm, plt_b_fill, plt_b_nofill, plt_s], ...
        { '$S$', '$S+\delta^+$', '$S-\delta^-$', 'MO lifts offer', 'other buy MO', 'sell MO' } );
set(leg, 'interpreter','latex','fontsize',16);

figure();
plot(t,hist_Q);
xlabel('Time', 'FontSize', 24, 'interpreter','latex');
ylabel('Inventory', 'FontSize', 24, 'interpreter','latex');

figure();
plot(t,hist_X);
xlabel('Time', 'FontSize', 24, 'interpreter','latex');
ylabel('Book Value', 'FontSize', 24, 'interpreter','latex');

end

