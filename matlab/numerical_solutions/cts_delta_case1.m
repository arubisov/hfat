function [ deltaplus, deltaminus ] = cts_delta_case1( h, Qmax, kappa, xi )
% Optimal delta^+ and delta^- for the continuous time Case 1 DPE.
%
% delta+*(t,z,q) = max{ 0 ; 1/kappa - 2*pi*(q <= -1) - h(t,z,q+1) + h(t,z,q) }
% delta-*(t,z,q) = max{ 0 ; 1/kappa - 2*pi*(q >= 1)  - h(t,z,q-1) + h(t,z,q) }
%
% Master's Thesis
% Date : 2015.07.15

deltaplus = zeros(size(h));
deltaminus = zeros(size(h));

deltaplus(:,:,1:end-1) = 1/kappa + h(:,:,1:end-1) - h(:,:,2:end);
deltaplus(:,:,end) = deltaplus(:,:,end-1);
deltaplus(:,:,1:Qmax) = deltaplus(:,:,1:Qmax) - 2*xi;

deltaminus(:,:,2:end) = 1/kappa + h(:,:,2:end) - h(:,:,1:end-1);
deltaminus(:,:,1) = deltaminus(:,:,2);
deltaminus(:,:,Qmax+2:end) = deltaminus(:,:,Qmax+2:end) - 2*xi;

deltaplus = max(deltaplus , 0);
deltaminus = max(deltaminus , 0);

end