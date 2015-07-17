%%% For each value in xn, return the index of the nearest value in xm.
function match_for_xn = match_mapping(xm, xn)

match_for_xn = zeros(length(xn), 1);
last_M = 1;
for N = 1 : length(xn)
    % search through M until we find a match.
    for M = last_M : length(xm)
        if M < numel(xm)
            dist_to_next = abs(xm(M+1) - xn(N));
        else
            match_for_xn(N) = M;
            break
        end
        dist_to_curr = abs(xn(N) - xm(M));

        if dist_to_next > dist_to_curr
            match_for_xn(N) = M;
            last_M = M;
            break
        else
            continue
        end

    end % M
end % N