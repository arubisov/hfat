% script plot_results
% X = NaN(3,4,252,23400);
% X(1,1,:,:) = FAROn;
% X(2,1,:,:) = FAROnp;
% X(3,1,:,:) = FAROnpp;
% X(3,2,:,:) = NTAPnpp;
% X(2,2,:,:) = NTAPnp;
% X(1,2,:,:) = NTAPn;
% X(1,3,:,:) = ORCLn;
% X(2,3,:,:) = ORCLnp;
% X(3,3,:,:) = ORCLnpp;
% X(3,4,:,:) = INTCnpp;
% X(2,4,:,:) = INTCnp;
% X(1,4,:,:) = INTCn;

tickers = {'FARO','NTAP','ORCL','INTC'};
strategies = 1:3;

t = 9.5 + 1/3600 : 1/3600 : 16;

% X - PnL
% Q - Inventory
% T - Number of Trades

% idx = ~isnan(X_OOS(1,1,:));
% X = X_OOS(:,:,idx);
% Q = Q_OOS(:,:,idx);
% T = T_OOS(:,:,idx,:);

len = size(X,4);

plotstep = 20;
idx = 1:plotstep:len;

ColorSet = varycolor(4);    

for ticker = 1:numel(tickers)
    figure();
    set(gca, 'ColorOrder', ColorSet);
    hold all;
    for strat = 1:numel(strategies)
        plot(t(idx),reshape(nanmean(X(strat,ticker,:,idx),3),1,numel(idx)),'-','LineWidth',1.5);
    end
    title(sprintf('%s',tickers{ticker}));
    xlim([9.5 16]);
    %legend(strategies);
    matlab2tikz(sprintf('%s_naive_strat_comp.tikz',tickers{ticker}));
end