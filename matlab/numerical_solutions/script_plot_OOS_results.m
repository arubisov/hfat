% script plot_results

tickers = {'FARO','NTAP','ORCL','INTC'};
strategies = {'Naive','Naive+','Naive++','Cts Stoch Ctrl','Dscr Stoch Ctrl','Cts Stoch Ctrl w NMC','Dscr Stoch Ctrl w NMC'};

% X - PnL
% Q - Inventory
% T - Number of Trades

len = size(Q,4);

red = 1/255 * [ 148 0 0 ];
cyan = 1/255 * [ 0 89 89 ];
blue = 1/255 * [ 0 30 99 ];
green = 1/255 * [ 0 118 0 ];
purple = 1/255 * [ 64 0 99 ];
orange = 1/255 * [ 148 67 0 ];
yellow = 1/255 * [ 148 99 0 ];

colors = {red,cyan,yellow,purple,orange,blue,green};

for ticker = 1:numel(tickers)
    figure();
    hold on;
    for strat = 1:numel(strategies)
        plot(reshape(nanmean(X(strat,ticker,:,:),3),len,1),'Color',colors{strat},'LineWidth',1);
    end
    hold off;
    title(sprintf('%s',tickers{ticker}));
    legend(strategies);
end