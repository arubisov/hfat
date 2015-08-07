function [] = printresulttable( X, Xinv, Xnum )

ret = nanmean(X(:,end));
sharpe = nanmean(X(:,end)) / nanstd(X(:,end));
numt = round(nanmean(Xnum));
inv = nanmean(nanmean(Xinv,2),1);
winidx = X(:,end) > 0;
lossidx = X(:,end) < 0;
winperc = sum(winidx) / size(X,1);
avgloss = mean(X(lossidx,end));
maxloss = min(X(lossidx,end));
avgwin = mean(X(winidx,end));
maxwin = max(X(winidx,end));

fprintf('%0.3f & %0.3f & %d & %0.2f & %0.2f & %0.3f & %0.3f & %0.3f & %0.3f \\\\ \n', ...
    ret, sharpe, numt, inv, winperc, avgloss, maxloss, avgwin, maxwin);