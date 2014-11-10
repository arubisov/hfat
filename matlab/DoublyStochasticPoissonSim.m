%% Simulation of a Doubly Stochastic Poisson Process (Markov Modulated Poisson Process)
function [param_G, param_lambda] = DoublyStochasticPoissonSim(G, lambda, num_arrivals, num_paths, rand_seed)
    if ~all([size(lambda,2), size(G,1), size(G,2)] == size(G,1))
        error('Dimensionality mismatch: Poisson intensities and generator matrix.');
    end

    rng(rand_seed);
    num_bins = size(G,1);
    param_G = zeros(num_bins,num_bins,num_paths);
    param_lambda = zeros(2,num_bins,num_paths);   
    
    for path = 1 : num_paths
        % initialize
        arrivals = zeros(2,num_bins);               % reset arrival count
        state = randi(3,1,1);                       % choose initial state
        clockarrival(1) = expon(lambda(1,state));   % reset arrival clocks
        clockarrival(2) = expon(lambda(2,state));   % reset arrival clocks
        clocktransition = expon(-G(state,state));   % reset transition clock
        binholdingtime = 0;                         % reset time since regime transition
        bintotaltime = zeros(num_bins,1);           % reset times spent in regimes
        transitions = zeros(num_bins);              % reset transition counts
        
        while sum(sum(arrivals)) < num_arrivals
            [timetoarrival,arrivalindex] = min(clockarrival);
            if timetoarrival < clocktransition
                clockarrival(:) = clockarrival(:) - timetoarrival;
                clocktransition = clocktransition - timetoarrival;
                binholdingtime = binholdingtime + timetoarrival;
                arrivals(arrivalindex,state) = arrivals(arrivalindex,state) + 1;
                clockarrival(arrivalindex) = expon(lambda(arrivalindex,state));
            else
                clockarrival(:) = clockarrival(:) - clocktransition;
                bintotaltime(state) = bintotaltime(state) + binholdingtime + clocktransition;
                newstate = transition(state,G);
                transitions(state,newstate) = transitions(state,newstate) + 1;
                state = newstate;
                binholdingtime = 0;
                clocktransition = expon(-G(state,state));
                clockarrival(1) = expon(lambda(1,state));
                clockarrival(2) = expon(lambda(2,state));
            end
        end

        % re-calculate model parameters based on simulated path
        param_G(:,:,path) = estimateG(transitions,num_bins,bintotaltime);
        param_lambda(:,:,path) = estimateLambda(arrivals,num_bins,bintotaltime);
        
    end %path

end

function newstate = transition(oldstate,G)
    % state transition
    if oldstate == 1 
        if rand < G(1,2)/(G(1,2)+G(1,3))
            newstate = 2;
        else
            newstate = 3;
        end
    elseif oldstate == 2
        if rand < G(2,1)/(G(2,1)+G(2,3))
            newstate = 1;
        else
            newstate = 3;
        end
    else
        if rand < G(3,1)/(G(3,1)+G(3,2))
            newstate = 1;
        else
            newstate = 2;
        end
    end
end

function y = expon(x)
    y = (-1/x) * log(rand);
end

%==================================================================
% PARAMETER RE-ESTIMATION
%==================================================================

% estimate generator matrix G for the underlying CTMC of regime switching.
function simG = estimateG(transitions, num_bins, bintotaltime)
    simG = transitions;

    for bin = 1 : num_bins
        simG(bin,:) = simG(bin,:) / bintotaltime(bin);
        simG(bin,bin) = -sum(simG(bin,:));
    end
end

% estimate the Poisson process intensities
function simLambda = estimateLambda(arrivals, num_bins, bintotaltime)
    simLambda = arrivals;

    for bin = 1 : num_bins
        simLambda(:,bin) = simLambda(:,bin) / bintotaltime(bin);
    end
end
