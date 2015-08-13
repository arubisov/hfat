function [ ] = plot_single_backtest(  hist_X, hist_Q, hist_Z, hist_Sb, hist_Sa, hist_dp, hist_dm, hist_their_Mb, hist_their_Ms, hist_our_Mb, hist_our_Ms, hist_Fillb, hist_Fills, dt_Z )
% Mimic simulation plot from STA4505 Ch12, Figure 12.7
%
% Master's Thesis
% Date  : 2015.07.29

savetxt = 'dscr_nFPC';

T1 = 9.5 * 3600000;
T2 = 16 * 3600000;

% x axis for everything except hist_S, which has its own in first column.
t = [T1 + dt_Z:dt_Z:T2];
t = t/3600000;

% were restring range to 10.975 to 11. 
% 10.975 == 5310
% 11 == 5400
start = 5310;
finish = 5400;
hist_X = hist_X(start:finish);
hist_Q = hist_Q(start:finish);
hist_Z = hist_Z(start:finish);
hist_Sb = hist_Sb(start:finish);
hist_Sa = hist_Sa(start:finish);
hist_dp = hist_dp(start:finish);
hist_dm = hist_dm(start:finish);
hist_their_Mb = hist_their_Mb(start:finish);
hist_their_Ms = hist_their_Ms(start:finish);
hist_our_Mb = hist_our_Mb(start:finish);
hist_our_Ms = hist_our_Ms(start:finish);
hist_Fillb = hist_Fillb(start:finish);
hist_Fills = hist_Fills(start:finish);
t = t(start:finish);

hist_S = (hist_Sb+hist_Sa)/2;

figure();
hold on
plt_mid = plot(t, hist_S,'-k','linewidth',3 );
plt_dm = plot(t, hist_Sa + hist_dm,'Color',[.5,.5,.5],'linewidth',2);
plt_dp = plot(t, hist_Sb - hist_dp,'Color',[.5,.5,.5],'linewidth',2);

% Buy MOs that lift our sell LO
iMOb = ~isnan(hist_their_Mb) & ~isnan(hist_Fills);
tMOb = t(iMOb);
SMOb = hist_S(iMOb);
SdMOb = hist_Sa(iMOb) + hist_dm(iMOb);
for k = 1 : length(tMOb)
    plot(tMOb(k) * [1 1], [SMOb(k) SdMOb(k)], '-', 'Color', [0.65098,0.80784,0.89020], 'linewidth', 2 );
    plt_b_fill = plot(tMOb(k) , SdMOb(k), '-o', 'Color', [0.65098,0.80784,0.89020], 'markerfacecolor',[0.65098,0.80784,0.89020], 'linewidth', 2   );
end

% Buy MOs that do not lift our sell LO
iMOb = ~isnan(hist_their_Mb) & isnan(hist_Fills);
tMOb = t(iMOb);
SMOb = hist_S(iMOb);
SdMOb = hist_their_Mb(iMOb);
for k = 1 : length(tMOb)
    plot(tMOb(k) * [1 1] , [SMOb(k) SdMOb(k)], '--', 'Color', [0.65098,0.80784,0.89020], 'linewidth', 2  );
    plt_b_nofill = plot(tMOb(k) , SdMOb(k), '--o','Color', [0.65098,0.80784,0.89020], 'linewidth', 2  );
end

% Sell MOs that lift our buy LO
iMOb = ~isnan(hist_their_Ms) & ~isnan(hist_Fillb);
tMOb = t(iMOb);
SMOb = hist_S(iMOb);
SdMOb = hist_Sb(iMOb) - hist_dp(iMOb);
for k = 1 : length(tMOb)
    plot(tMOb(k) * [1 1], [SMOb(k) SdMOb(k)], '-', 'Color', [0.69804,0.87451,0.54118], 'linewidth', 2 );
    plt_s_fill = plot(tMOb(k) , SdMOb(k), '-o', 'Color', [0.69804,0.87451,0.54118], 'markerfacecolor',[0.69804,0.87451,0.54118], 'linewidth', 2  );
end

% Sell MOs that do not lift our buy LO
iMOb = ~isnan(hist_their_Ms) & isnan(hist_Fillb);
tMOb = t(iMOb);
SMOb = hist_S(iMOb);
SdMOb = hist_their_Ms(iMOb);
for k = 1 : length(tMOb)
    plot(tMOb(k) * [1 1] , [SMOb(k) SdMOb(k)], '--', 'Color', [0.69804,0.87451,0.54118], 'linewidth', 2  );
    plt_s_nofill = plot(tMOb(k) , SdMOb(k),  '--o', 'Color', [0.69804,0.87451,0.54118], 'linewidth', 2  );
end

% Our Buy MOs
iMOb = ~isnan(hist_our_Mb);
tMOb = t(iMOb);
SMOb = hist_S(iMOb);
SdMOb = hist_our_Mb(iMOb);
for k = 1 : length(tMOb)
    plot(tMOb(k) * [1 1] , [SMOb(k) SdMOb(k)], '-','Color', [0.20000,0.62745,0.17255], 'linewidth', 2  );
    plt_our_b = plot(tMOb(k) , SdMOb(k), '-o', 'Color', [0.20000,0.62745,0.17255], 'MarkerFaceColor', [0.20000,0.62745,0.17255], 'linewidth', 2  );
end
plt_our_b = plot(1 , 1, '-o', 'Color', [0.20000,0.62745,0.17255], 'MarkerFaceColor', [0.20000,0.62745,0.17255], 'linewidth', 2  );


% Our Sell MOs
iMOb = ~isnan(hist_our_Ms);
tMOb = t(iMOb);
SMOb = hist_S(iMOb);
SdMOb = hist_our_Ms(iMOb);
for k = 1 : length(tMOb)
    plot(tMOb(k) * [1 1] , [SMOb(k) SdMOb(k)], '-', 'Color',[0.12157,0.47059,0.70588],'linewidth', 2  );
    plt_our_s = plot(tMOb(k) , SdMOb(k), '-o',  'Color',[0.12157,0.47059,0.70588], 'MarkerFaceColor',[0.12157,0.47059,0.70588],'linewidth', 2 );
end
plt_our_s = plot(1 , 1, '-o',  'Color',[0.12157,0.47059,0.70588], 'MarkerFaceColor',[0.12157,0.47059,0.70588],'linewidth', 2 );

hold off
xlabel('Time (h)', 'FontSize', 24, 'interpreter','latex');
ylabel('Price', 'FontSize', 24, 'interpreter','latex');

set(gca,'fontsize',18);
leg = legend( [plt_mid, plt_dp, plt_our_s, plt_b_fill, plt_b_nofill, plt_our_b, plt_s_fill, plt_s_nofill], ...
        { '$S$', '$S \pm \delta^\pm$', 'Our Sell MO', 'Ext Buy MO lifts our sell LO', 'Ext Buy MO arrives', 'Our Buy MO', 'Ext Sell MO lifts our buy LO', 'Ext Sell MO arrives' } );
set(leg, 'interpreter','latex','fontsize',16);
xlim([10.975 11]);
matlab2tikz(sprintf('samplepath_%s_paths.tikz',savetxt));

figure();
plot(t,hist_Q,'-k','LineWidth',2);
xlabel('Time (h)', 'FontSize', 24, 'interpreter','latex');
ylabel('Inventory', 'FontSize', 24, 'interpreter','latex');
xlim([10.975 11]);
ylim auto;
matlab2tikz(sprintf('samplepath_%s_inventory.tikz',savetxt));

figure();
hold on;
dm = plot(t,hist_dm,'-','Color',[.6,.6,.6],'linewidth',2);
dp = plot(t,-hist_dp,'-','Color',[.4,.4,.4],'linewidth',2);
hold off;
leg = legend( [dm, dp], '$\delta^-$ (sell depth)', '$\delta^+$ (buy depth)' );
set(leg, 'interpreter','latex','fontsize',16);
xlabel('Time (h)', 'FontSize', 24, 'interpreter','latex');
ylabel('LO Posting Depths', 'FontSize', 24, 'interpreter','latex');
xlim([10.975 11]);
set(gca,'yticklabel',num2str(abs(get(gca,'ytick').')))
matlab2tikz(sprintf('samplepath_%s_depths.tikz',savetxt));


% figure();
% plot(t,hist_Z,'-k','LineWidth',2);
% xlabel('Time (h)', 'FontSize', 24, 'interpreter','latex');
% ylabel('Order Imbalance', 'FontSize', 24, 'interpreter','latex');
% xlim([10.975 11]);
% matlab2tikz(sprintf('samplepath_%s_imbalance.tikz',savetxt));

figure();
plot(t,hist_X,'-k','LineWidth',2);
xlabel('Time (h)', 'FontSize', 24, 'interpreter','latex');
ylabel('Book Value', 'FontSize', 24, 'interpreter','latex');
xlim([10.975 11]);
matlab2tikz(sprintf('samplepath_%s_bookvalue.tikz',savetxt));

end