%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Generating MMPP-3 interarrival times
% Author: Hui Li (hui.li@computer.org).
% March, 2006. Licensed under GPL.
% 
% references:
% The MMPP cookbook. Perf. Eval. 18, 149-171, 1992.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function f = gen_MMPP_3(Q, lambda, arrivalsToSimulate)

fid = fopen('mmpp3.iat','w');

% initialize
arrivalsCount = 0;
timeSinceLastArrival = 0;
% starting state (state = 1, 2, 3)
state = ~(rand < 0.3) + 1;
timeToArrival = expon(lambda(state));
timeToTransition = expon(-Q(state,state));

while arrivalsCount < arrivalsToSimulate
    if timeToArrival < timeToTransition
        timeToTransition = timeToTransition - timeToArrival;
        timeSinceLastArrival = timeSinceLastArrival + timeToArrival;
        %print out timeSinceLastArrival
        fprintf(fid, '%f\n', timeSinceLastArrival);
        timeSinceLastArrival = 0;
        timeToArrival = expon(lambda(state));
        arrivalsCount = arrivalsCount + 1;
    else
        timeToArrival = timeToArrival - timeToTransition;
        timeSinceLastArrival = timeSinceLastArrival + timeToTransition;
        state = transition(state,Q);
        timeToTransition = expon(-Q(state,state));
    end
end

fclose(fid);

function y = expon(x)
y = (-1/x)*log(rand);

function stat = transition(S, Q)
% state transition
if S == 1 
    if rand < Q(1,2)/(Q(1,2)+Q(1,3))
        stat = 2;
    else
        stat = 3;
    end
elseif S == 2
    if rand < Q(2,1)/(Q(2,1)+Q(2,3))
        stat = 1;
    else
        stat = 3;
    end
else
    if rand < Q(3,1)/(Q(3,1)+Q(3,2))
        stat = 1;
    else
        stat = 2;
    end
end