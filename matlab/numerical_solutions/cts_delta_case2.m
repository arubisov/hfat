function [ deltaplus, deltaminus ] = cts_delta_case2( h )
% Optimal delta^+ and delta^- for the continuous time Case 1 DPE.
%
% delta+*(t,z,q) = max{ 0 ; 1/kappa - 2*pi*(q <= -1) - h(t,z,q+1) + h(t,z,q) }
% delta-*(t,z,q) = max{ 0 ; 1/kappa - 2*pi*(q >= 1)  - h(t,z,q-1) + h(t,z,q) }
%
% Master's Thesis
% Date : 2015.07.15

global kappa
global gamma
global Qrange
global xi

newQrange = 11:31;
Qrange = Qrange(newQrange);

deltaplus = 1/gamma * log(1 + gamma/kappa) + h(:,:,newQrange) - h(:,:,newQrange+1);
deltaplus(:,:,11) = deltaplus(:,:,11) - xi;
deltaplus(:,:,1:10) = deltaplus(:,:,1:10) - 2*xi;

deltaminus = 1/gamma * log(1 + gamma/kappa) + h(:,:,newQrange) - h(:,:,newQrange-1);
deltaminus(:,:,11) = deltaminus(:,:,11) - xi;
deltaminus(:,:,12:end) = deltaminus(:,:,12:end) - 2*xi;

deltaplus = max(deltaplus , 1/gamma * log(1 + gamma/kappa) - 2*xi);
deltaminus = max(deltaminus , 1/gamma * log(1 + gamma/kappa) - 2*xi);

end