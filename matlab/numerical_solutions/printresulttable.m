function [] = printresulttable( X,Q,T )

tickers = {'AAPL'};
strategies = {'Cts','Dscr','Cts w nFPC','Dscr w nFPC'};

for ticker = 1:numel(tickers)
    fprintf('\\multicolumn{9}{l}{\\texttt{%s}} \\\\ \n',tickers{ticker});
        for strat = 1:numel(strategies)
            
            ret = mean(X(strat,ticker,:));
            sharpe = ret / std(X(strat,ticker,:));
            nummo = round(mean(T(strat,ticker,:,1)));
            numlo = round(mean(T(strat,ticker,:,2)));
            inv = mean(Q(strat,ticker,:));
            winidx = X(strat,ticker,:) > 0;
            lossidx = X(strat,ticker,:) < 0;
            winperc = sum(winidx) / size(X,3);
            maxloss = min(X(strat,ticker,lossidx));
            maxwin = max(X(strat,ticker,winidx));
            
            fprintf('%s & %0.3f & %0.3f & %d & %d & %0.2f & %0.2f & %0.3f & %0.3f \\\\ \n', ...
                strategies{strat}, ret, sharpe, nummo, numlo, inv, winperc, maxloss, maxwin);
        end
end