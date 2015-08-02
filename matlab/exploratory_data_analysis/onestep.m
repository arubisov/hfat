function [ P ] = onestep( G, dt )
% Convert an infinitesimal generator matrix G to the associated transition probability matrix, moving forward in time by dt milliseconds.
    P = expm(G*dt/1000);
end