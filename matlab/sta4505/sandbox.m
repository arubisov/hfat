
t = 1:1:300/0.002;

fig = figure(2);
clf(fig);
axes1 = axes('Parent',fig,...
    'Position',[0.192857142857143 0.173809523809524 0.712142857142855 0.751190476190478],...
    'FontSize',18);
%box(axes1,'on');
%hold(axes1,'all');


plt_mid = plot(t, hist_S(1,:),'-k','linewidth',3 );
hold on
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

% set(gca,'fontsize',18);
% xlabel('Time', 'fontsize',24,'interpreter','latex');
% ylabel('Price', 'fontsize',24,'interpreter','latex');
% leg = legend( [plt_mid, plt_depth, plt_b_fill, plt_b_nofill, plt_s], ...
%         { '$S$', '$S+\delta$', 'MO lifts offer', 'other buy MO', 'sell MO' } );
% set(leg, 'interpreter','latex','fontsize',16);