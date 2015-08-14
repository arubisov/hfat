% script plot_results

%tickers = {'FARO','NTAP','ORCL','INTC'};
tickers = {'ORCL','INTC'};
strategies = {'Cts Stoch Ctrl','Dscr Stoch Ctrl','Cts Stoch Ctrl w nFPC','Dscr Stoch Ctrl w nFPC'};

% X - PnL
% Q - Inventory
% T - Number of Trades

idx = ~isnan(X_OOS(1,1,:));
X = X_OOS(:,:,idx);
Q = Q_OOS(:,:,idx);
T = T_OOS(:,:,idx,:);

len = size(X,3);

red = 1/255 * [ 148 0 0 ];
cyan = 1/255 * [ 0 89 89 ];
blue = 1/255 * [ 0 30 99 ];
green = 1/255 * [ 0 118 0 ];
purple = 1/255 * [ 64 0 99 ];
orange = 1/255 * [ 148 67 0 ];
yellow = 1/255 * [ 148 99 0 ];

colors = {purple,green,cyan,orange};

for ticker = 1:numel(tickers)
    figure();
    hold on;
    for strat = 1:numel(strategies)
        plot(reshape(X(strat,ticker,:),len,1),'Color',colors{strat},'LineWidth',1.5);
    end
    hold off;
    title(sprintf('%s',tickers{ticker}));
    xlim([1 252]);
    %legend(strategies);
    matlab2tikz(sprintf('IS_annual_%s.tikz',tickers{ticker}));
end