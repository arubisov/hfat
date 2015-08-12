% for row=1:size(G,1)
%     for col=1:size(G,2)
%         fprintf('%6.3f & ',round(G(row,col)*1000)/1000);
%     end
%     fprintf('\b\b\\\\ \n');
% end

t = 9.5 + 1/3600 : 1/3600 : 16;

strategies = {'Cts Stoch Ctrl','Cts Stoch Ctrl w nFPC','Dscr Stoch Ctrl','Dscr Stoch Ctrl w nFPC'};
orange = 1/255 * [ 148 67 0 ];
blue = 1/255 * [ 0 30 99 ];
purple = 1/255 * [ 64 0 99 ];
yellow = 1/255 * [ 148 99 0 ];

colors = {purple,blue,orange,yellow};

figure();
hold on;
plot(t(1:20:end),q1(1:20:end),'Color',colors{1},'LineWidth',1.5);
plot(t(1:20:end),q2(1:20:end),'Color',colors{2},'LineWidth',1.5);
plot(t(1:20:end),q3(1:20:end),'Color',colors{3},'LineWidth',1.5);
plot(t(1:20:end),q4(1:20:end),'Color',colors{4},'LineWidth',1.5);    
hold off;
xlim([9.5 16]);
legend(strategies);
matlab2tikz('ORCL_comp4stoch_inv.tikz');
% 
% [h,pValue,stat,cValue,reg] = egcitest(Y(1:end,[1 2  3 4]),'test',{'t1','t2'});
% coeffs = reg.coeff;
% c0 = coeffs(1);
% b = coeffs(2:4);
% beta = [1;-b];
% figure();
% plot(t(1:10:end),Y(1:10:end,[1 2 3 4])*beta-c0,'LineWidth',1.5);
% title '{\bf Cointegrating Relation}';
% axis tight;
% legend off;
% grid on;