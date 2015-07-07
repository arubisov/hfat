function [ delta ] = optimal_delta( h )
% STA4505 Course Project - Ch12 on Order Imbalance
%   delta*(t,z,q) = max{ 1/kappa + h(t,z,q) - h(t,z,q-1) + E[epsilon_z] ; 0 }

global kappa
global epsilonplus
global Qrange
global Zrange

newQrange = 11:31;
Qrange = Qrange(newQrange);

delta = 1/kappa * ones(size(h(:,:,newQrange))) + h(:,:,newQrange) - h(:,:,newQrange-1);

for z = 1:length(Zrange)
    delta(:,z,:) = delta(:,z,:) + epsilonplus(z);
end

delta = max(delta,0);

end