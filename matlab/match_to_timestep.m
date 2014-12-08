%%% For each timestep value in xn, return the index of the <= timestep value in xm.
% So something happening at 2.04s would get mapped to 2s.
function match_for_xn = match_to_timestep(xm, xn)

match_for_xn = zeros(length(xn), 1);
last_M = 1;
for N = 1 : length(xn)
    % search through M until we find a match.
    for M = last_M : length(xm)
        if M < length(xm)
            dist_from_next = xn(N) - xm(M+1);
        else
            match_for_xn(N) = M;
            break
        end
        
        if dist_from_next < 0
            match_for_xn(N) = M;
            last_M = M;
            break
        else
            continue
        end

    end % M
end % N