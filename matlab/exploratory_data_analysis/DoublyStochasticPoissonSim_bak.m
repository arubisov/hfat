%% Simulation of a Doubly Stochastic Poisson Process (Markov Modulated Poisson Process)

classdef DoublyStochasticPoissonSim_bak < handle
    properties (SetAccess = private)
        num_paths            % Number of simulations to run
        num_arrivals        % Number of market order arrivals to simulate until
        lambda              % Arrival intensities for buy and sell market orders (sell, buy)
        G                   % Generator matrix for underlying CTMC
        num_bins            % Total number of regime bins in the CTMC
        state               % Current regime of the CTMC in the simulation
        arrivals            % Number of order arrivals in the simulation (sell, buy)
        transitions         % Number of regime transitions in the simulation
        clockarrival        % Time-to-arrival for Poisson processes (sell, buy)
        clocktransition     % Time-to-transition for CTMC
        bintotaltime        % Total time spent in each bin
        binholdingtime      % Time since last regime transition.
        param_G             % Re-estimated generator matrix along each sim path
        param_lambda        % Re-estimated lambda along each sim path
    end
    methods
        % class constructor
        function sim = DoublyStochasticPoissonSim_bak(G, lambda, num_arrivals, num_paths, rand_seed)            
            rng(rand_seed);
            sim.num_paths = num_paths;
            sim.num_arrivals = num_arrivals;
            sim.lambda = lambda;
            sim.G = G;
            if ~all([size(lambda,2), size(G,1), size(G,2)] == size(G,1))
                error('Dimensionality mismatch: Poisson intensities and generator matrix.');
            end
            sim.num_bins = size(G,1);
            sim.param_G = zeros(sim.num_bins,sim.num_bins,sim.num_paths);
            sim.param_lambda = zeros(2,sim.num_bins,sim.num_paths);
            sim.reset();
        end
        
        % maintenance
        function reset(sim)
            sim.arrivals = zeros(2,sim.num_bins);
            sim.clockarrival = zeros(2,1);
            sim.clocktransition = 0;
            sim.binholdingtime = 0;
            sim.bintotaltime = zeros(sim.num_bins,1);
            sim.transitions = zeros(sim.num_bins);
        end
        
        function RunSimulation(sim)

            for path = 1 : sim.num_paths
                sim.reset();                    % reset counters
                sim.state = randi(3,1,1);       % choose initial state
                sim.clockarrival = exprnd(1./sim.lambda(:,sim.state));
                sim.resetclocktransition();     % generate CTMC holding times

                while sum(sim.arrivals) < sim.num_arrivals
                    [timetoarrival,arrivalindex] = min(sim.clockarrival);
                    if timetoarrival < sim.clocktransition
                        sim.arrival(timetoarrival,arrivalindex);
                    else
                        sim.transition();
                    end
                end
                
                % re-calculate model parameters based on simulated path
                sim.param_G(:,:,path) = sim.estimateG();
                sim.param_lambda(:,:,path) = sim.estimateLambda();
            end
                
        end
        
        function [G, lambda] = getestimatedparams(sim)
           G = sim.param_G;
           lambda = sim.param_lambda;
        end
        
        function arrival(sim, timetoarrival, arrivalindex)
            sim.adjust_times(timetoarrival);            
            sim.arrivals(arrivalindex,sim.state) = sim.arrivals(arrivalindex,sim.state) + 1;
            sim.resetclockarrival(arrivalindex);
        end
        
        function transition(sim)
            sim.adjust_times(sim.clocktransition);
            sim.bintotaltime(sim.state) = sim.bintotaltime(sim.state) + sim.binholdingtime;
            sim.dotransition();
            sim.resetclocktransition();
            sim.binholdingtime = 0;
        end
        
        function dotransition(sim)
            % state transition
            if sim.state == 1 
                if rand < sim.G(1,2)/(sim.G(1,2)+sim.G(1,3))
                    sim.state = 2;
                    sim.transitions(1,2) = sim.transitions(1,2) + 1;
                else
                    sim.state = 3;
                    sim.transitions(1,3) = sim.transitions(1,3) + 1;
                end
            elseif sim.state == 2
                if rand < sim.G(2,1)/(sim.G(2,1)+sim.G(2,3))
                    sim.state = 1;
                    sim.transitions(2,1) = sim.transitions(2,1) + 1;
                else
                    sim.state = 3;
                    sim.transitions(2,3) = sim.transitions(2,3) + 1;
                end
            else
                if rand < sim.G(3,1)/(sim.G(3,1)+sim.G(3,2))
                    sim.state = 1;
                    sim.transitions(3,1) = sim.transitions(3,1) + 1; 
                else
                    sim.state = 2;
                    sim.transitions(3,2) = sim.transitions(3,2) + 1;
                end
            end
        end
        
        function resetclockarrival(sim, index)
            sim.clockarrival(index) = exprnd(1./sim.lambda(index,sim.state));
        end
        
        function resetclocktransition(sim)
            sim.clocktransition = exprnd(-1/sim.G(sim.state,sim.state));
        end
        
        function adjust_times(sim, timeadj)
            sim.clockarrival = sim.clockarrival - timeadj;
            sim.clocktransition = sim.clocktransition - timeadj;
            sim.binholdingtime = sim.binholdingtime + timeadj;
        end
        
        %==================================================================
        % PARAMETER RE-ESTIMATION
        %==================================================================
        
        % estimate generator matrix G for the underlying CTMC of regime switching.
        function simG = estimateG(sim)
            simG = sim.transitions;

            for bin = 1 : sim.num_bins
                simG(bin,:) = simG(bin,:) / sim.bintotaltime(bin);
                simG(bin,bin) = -sum(simG(bin,:));
            end
        end
        
        % estimate the Poisson process intensities
        function simLambda = estimateLambda(sim)
            simLambda = sim.arrivals;
            
            for bin = 1 : sim.num_bins
                simLambda(:,bin) = simLambda(:,bin) / sim.bintotaltime(bin);
            end
        end
    end
    
    methods (Static)
        % returns random variable draw from an exponential distribution
        % with intensity equal to lambda.
        function val = exp_dist(lambda)
            val = -log(rand())/lambda;
        end
    end
end