% script plot_results

figure();

FARO = [nanmean(FAROn(:,end)),nanmean(FAROnp(:,end)),nanmean(FAROnpp(:,end)),nanmean(FAROcts(:,end)),nanmean(FAROdscr(:,end))];
NTAP = [nanmean(NTAPn(:,end)),nanmean(NTAPnp(:,end)),nanmean(NTAPnpp(:,end)),nanmean(NTAPcts(:,end)),nanmean(NTAPdscr(:,end))];
ORCL = [nanmean(ORCLn(:,end)),nanmean(ORCLnp(:,end)),nanmean(ORCLnpp(:,end)),nanmean(ORCLcts(:,end)),nanmean(ORCLdscr(:,end))];
INTC = [nanmean(INTCn(:,end)),nanmean(INTCnp(:,end)),nanmean(INTCnpp(:,end)),nanmean(INTCcts(:,end)),nanmean(INTCdscr(:,end))];

y = [FARO; NTAP; ORCL; INTC];
b = bar(y);

red = 1/255 * [ 193 56 49 ];
blue = 1/255 * [ 0 160 219 ];
green = 1/255 * [ 105 255 105 ];
purple = 1/255 * [ 163 0 219 ];
orange = 1/255 * [ 247 148 29 ];

set(b(1),'FaceColor',red,'EdgeColor',red);
set(b(2),'FaceColor',blue,'EdgeColor',blue);
set(b(3),'FaceColor',green,'EdgeColor',green);
set(b(4),'FaceColor',purple,'EdgeColor',purple);
set(b(5),'FaceColor',orange,'EdgeColor',orange);

set(gca,'XTickLabel',{'FARO', 'NTAP', 'ORCL', 'INTC'})

h = legend([b(1),b(2),b(3),b(4),b(5)],'Naive','Naive+','Naive++','Continuous','Discrete','location','eastoutside');
%pos = get(h,'position');
%set(h, 'position',[0.8 0.5 pos(3:4)])
