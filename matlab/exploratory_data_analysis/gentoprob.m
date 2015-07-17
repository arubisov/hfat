function [ T ] = gentoprob( G )
% Convert an infinitesimal generator matrix G to the associated
% transition probability matrix.

    T = max(G,0);
    T = T ./ repmat(sum(T,2),1,size(G,1));

end

