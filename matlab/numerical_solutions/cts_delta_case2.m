function [ deltaplus, deltaminus ] = cts_delta_case2( h )
% Optimal delta^+ and delta^- for the continuous time Case 2 DPE.
%
% delta+*(t,z,q) = max{ 0 ; 1/kappa - 2*pi*(q <= -1) - h(t,z,q+1) + h(t,z,q) }
% delta-*(t,z,q) = max{ 0 ; 1/kappa - 2*pi*(q >= 1)  - h(t,z,q-1) + h(t,z,q) }
%
% Master's Thesis
% Date : 2015.07.15

global kappa
global gamma
global Qmax
global xi

deltaplus = zeros(size(h));
deltaminus = zeros(size(h));

deltaplus(:,:,1:end-1) = 1/gamma * log(1 + gamma/kappa) + h(:,:,1:end-1) - h(:,:,2:end);
deltaplus(:,:,end) = deltaplus(:,:,end-1);
deltaplus(:,:,Qmax+1) = deltaplus(:,:,Qmax+1) - xi;
deltaplus(:,:,1:Qmax) = deltaplus(:,:,1:Qmax) - 2*xi;

deltaminus(:,:,2:end) = 1/gamma * log(1 + gamma/kappa) + h(:,:,2:end) - h(:,:,1:end-1);
deltaminus(:,:,Qmax+1) = deltaminus(:,:,Qmax+1) - xi;
deltaminus(:,:,Qmax+2:end) = deltaminus(:,:,Qmax+2:end) - 2*xi;

% is this correct? revisit... should be lower bound zero...
deltaplus = max(deltaplus , 1/gamma * log(1 + gamma/kappa) - 2*xi);
deltaminus = max(deltaminus , 1/gamma * log(1 + gamma/kappa) - 2*xi);

end