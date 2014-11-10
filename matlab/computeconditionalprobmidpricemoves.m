function [moves_up, moves_down] = computeconditionalprobmidpricemoves(data, mu_mid, mu_IB, rho, dt_mid_diff)

    % imbalance at all events
    idx = (data.Event(:,1) >= 9.5*3600000 & data.Event(:,1) <= 16*3600000);
    IB_all = ( data.BuyVolume(idx,1) - data.SellVolume(idx,1) ) ./ ( data.BuyVolume(idx,1) + data.SellVolume(idx,1) );
    dt = diff(data.Event(idx,1));

    % change in mid price - lookahead time is dt_mid_diff (already factors
    % in smoothing of prices via averaging window)
    deltaMid = mu_mid(1+dt_mid_diff:end) - mu_mid(1:end-dt_mid_diff);

    moves_up = NaN(length(rho)-1,1);
    moves_down = NaN(length(rho)-1,1);
%     moves_nochg = NaN(length(rho)-1,1);

    for k = 1 : length(rho)-1

        % imbalance range
        if k < length(rho)-1
            idx_IB = ( mu_IB >= rho(k) & mu_IB < rho(k+1) );
            idx_t = ( IB_all >= rho(k) & IB_all < rho(k+1) );
        else
            idx_IB = ( mu_IB >= rho(k) & mu_IB <= rho(k+1) );
            idx_t = ( IB_all >= rho(k) & IB_all <= rho(k+1) );
        end

        % find total time spent in this IB range
        timeIn = sum(idx_t(1:end-1) .* dt);

        % Number of times mid price moves upward %
        numMoves = sum(idx_IB(1:end-dt_mid_diff) & (deltaMid(:,1) > 0));
        moves_up(k) = numMoves/timeIn;

        % Number of times mid price moves downward %
        numMoves = sum(idx_IB(1:end-dt_mid_diff) & (deltaMid(:,1) < 0));
        moves_down(k) = numMoves/timeIn;

        % Number of no-change %
%         numMoves = sum(idx_IB(1:end-1) & (deltaMid(:,1) == 0));
%         moves_nochg(k) = numMoves %/timeIn;

    end
end