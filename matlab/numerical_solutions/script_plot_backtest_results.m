% script plot_results

%tickers = {'FARO','NTAP','ORCL','INTC'};
tickers = {'INTC'};
strategies = {'Cts Stoch Ctrl','Dscr Stoch Ctrl','Cts Stoch Ctrl w nFPC','Dscr Stoch Ctrl w nFPC'};

% X - PnL
% Q - Inventory
% T - Number of Trades

% idx = ~isnan(X_OOS(1,1,:));
% X = X_OOS(:,:,idx);
% Q = Q_OOS(:,:,idx);
% T = T_OOS(:,:,idx,:);

len = size(X,3);

ColorSet = varycolor(4);    

for ticker = 1:numel(tickers)
    figure();
    set(gca, 'ColorOrder', ColorSet);
    hold all;
    for strat = 1:numel(strategies)
        plot(reshape(X(strat,ticker,:),len,1),'-','LineWidth',1.5);
    end
    hold off;
    title(sprintf('%s',tickers{ticker}));
    xlim([1 252]);
    %legend(strategies);
    matlab2tikz(sprintf('OOS_annual_%s_theappleway.tikz',tickers{ticker}));
end