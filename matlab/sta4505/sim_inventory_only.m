function [ hist_Q] = sim_inventory_only(num_paths, rand_seed, deltastar)
% STA4505 Course Project - Ch12 on Order Imbalance
% Simulation of optimal liquidation using limit orders.
% To simulate the Markov-modulated Poisson arrival processes, we use a
% thinning algorithm. (See http://sfb649.wiwi.hu-berlin.de/ ...
%                        fedc_homepage/xplore/tutorials/stfhtmlnode90.html)

    global kappa
    global alpha
    global phi
    global T
    global dt
    global lambdaplus
    global epsilonplus
    global epsilonplustable
    global G
    global Qrange
    
    epsilonpluscdf = cumsum(epsilonplustable(:,2:6));
    lambdaplusbar = max(lambdaplus);
    
    T_cumsum = cumsum(gentoprob(G),2);
    
    if ~all([size(lambdaplus,1), size(epsilonplus,1), ...
            size(G,1), size(G,2)] == size(G,1))
        error('Dimensionality mismatch: arrival rates and inf generator.');
    end

    rng(rand_seed);
    num_bins = size(G,1);
    hist_Q = NaN(num_paths,T/dt);
        
    h = waitbar(0, 'Simulating...');
    
    for path = 1 : num_paths
        % initialize
        S = 33.61;                                  % initial stock price
        Q = 4;                                      % initial inventory = 4
        Z = randi(num_bins,1,1);                    % choose initial state
        clockarrivalbuy = expon(lambdaplus(Z));     % reset arrival clocks
        clocktransition = expon(-G(Z,Z));           % reset transition clock
        binholdingtime = 0;                         % reset time since regime transition
        arrivalbuyholdingtime = 0;                  % reset time since buy MO arrived
        
        for t = 1 : T/dt
            delta = deltastar(t,Z,find(Qrange==Q,1));
            
            % move forward in time by dt
            binholdingtime = binholdingtime + dt;
            arrivalbuyholdingtime = arrivalbuyholdingtime + dt;
            
            % check whether MOs arrived
            if clockarrivalbuy < arrivalbuyholdingtime
                if poissonthinning(lambdaplus(Z), lambdaplusbar)
                    % Buy MO
                    depth = -log(rand)/kappa;
                    pricechg = newpricechg(Z,epsilonpluscdf);
                    S = S + pricechg;
                    arrivalbuyholdingtime = 0;
                    clockarrivalbuy = expon(lambdaplus(Z));

                    % lift our limit order?
                    if Q > 0
                        if depth >= delta
                            Q = Q - 1;
                        end
                    end
                end
            end
            
            % check on Markov Chain transitions
            if clocktransition < binholdingtime
                % transition to new state
                Z = transition(Z,T_cumsum);
                binholdingtime = 0;
                clocktransition = expon(-G(Z,Z));
            end
            
            % document everything in the hists
            hist_Q(path,t) = Q;
        end
        waitbar(path / num_paths) 
    end
    close(h)

end

function outcome = poissonthinning(lambda, lambdabar)
% Poisson thinning for non-homogeneous Poisson processes.
    if rand > lambda/lambdabar
        outcome = 0;
    else
        outcome = 1;
    end
end

function pricechg = newpricechg(state,cdf)
% Draw a random price change from the given cdf.
    global epsilonplustable
    
    x = sum(cdf(:,state) <= rand) + 1;
    pricechg = epsilonplustable(x,1);
end

function newstate = transition(oldstate,A)
% Perform Markov Chain transition. The input matrix A is the cumulative
% distribution of the transition probability matrix. 
    this_cum_dist = A(oldstate,:);
    newstate = find(this_cum_dist > rand, 1);
end

function y = expon(mu)
% Draw a random number from an exponentrial distribution with RATE mu. Note
% that MATLAB's exprnd function takes as input the MEAN. 
    y = exprnd(1/mu);
end

function [ T ] = gentoprob( G )
% Convert an infinitesimal generator matrix G to the associated
% transition probability matrix.

    T = max(G,0);
    T = T ./ repmat(sum(T,2),1,size(G,1));

end