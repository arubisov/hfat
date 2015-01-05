%% Calculate and return sum of daily returns given year of bookvalues.
% year_bookvals     - as obtained from script_runnaive.m

function sumdailyret = returnsumdailyret(year_bookvals, year_midprices)

    earlyclose = isnan(year_bookvals(:,end));
    fullday = ~earlyclose;
    
    sumdailyret = sum(year_bookvals(fullday,end));
    summidmoves = sum(year_midprices(fullday,end) - 1);
    
    A = year_bookvals(earlyclose,:);
    B = ~isnan(A);
    % indices
    lastidx = find(B(1,:), 1, 'last');
    
    sumdailyret = sumdailyret + sum(year_bookvals(earlyclose,lastidx));
    summidmoves = summidmoves + sum(year_midprices(earlyclose,lastidx) - 1);
    
    fprintf('Sum of normalized daily returns: %.2f\n', sumdailyret);
    fprintf('Sum of normalized mid price moves: %.2f\n', summidmoves);

end