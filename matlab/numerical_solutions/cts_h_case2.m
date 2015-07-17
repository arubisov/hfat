function [ h ] = cts_h_case2( )
% Numerical solution to the continuous time Case 2 DPE ansatz h(t,z,q).
% 
% Utilize an explicit finite difference scheme with backward approximation
% to solve the quasi-variational inequality obtained for the first
% performance criteria (maximum terminal wealth). At each step, rather than
% use the calculated finite differences value, take the maximum between it
% and the "intrinsic" stopping region value, since we know the value of
% h(t,z,q) at q=0 and can bootstrap off that. 
%
% The optimal depths can be solved using the resulting function.
%
% Master's Thesis
% Date  : 2015.07.17

global kappa
global gamma
global alpha
global phi
global xi
global Qmax
global Qrange
global Zrange
global T
global dt
global muplus
global muminus
global num_bins
global G

% Parameters
data = load('./data/ORCL_20130515.mat');    %
data = data.data;
dt_Z = 1000;                                %
num_bins = 5;                               %
avg_method = 5;                             %

[ t, binseries, pricechgseries, G, mu_IB ] = ...
    compute_G( data, dt_Z, num_bins, avg_method );
[ oneDseries ] = get1Dseries( binseries, pricechgseries, num_bins );
[ eta_table ] = compute_eta( oneDseries, pricechgseries, num_bins );
[ muplus, muminus ] = compute_mu( data, oneDseries, dt_Z, num_bins );
kappa = 100;
gamma = 100;
alpha = 0.01;
phi = 0.00001;
xi = 0.01;
% compute expected values
eta = sum(repmat(eta_table(:,1),1,num_bins*3).*eta_table(:,2:end),1)';

% finite scheme setup
Qmax = 20;
Qrange = -Qmax:1:Qmax;
Zrange = 1:num_bins*3;
T = 50.0;
dt = 0.01;

h = zeros(T/dt,length(Zrange),length(Qrange));

% Establish terminal condition h(T,z,q) = -alpha*q^2
h(end, :, :) = repmat(-alpha*Qrange.*Qrange,num_bins*3,1);

progress = waitbar(0, 'Calculating numerical solution...');

for i = round((T-dt)/dt):-1:1
    dqplus = zeros(length(Zrange),length(Qrange));
    dqminus = zeros(length(Zrange),length(Qrange));
    
    % dq^+ = h(t,z,q) - h(t,z,q-1)
    dqplus(:,2:end) = h(i+1,:,2:end) - h(i+1,:,1:end-1);
    dqplus(:,1) = h(i+1,:,2) - h(i+1,:,1);
    % dq^- = h(t,z,q) - h(t,z,q+1)
    dqminus(:,1:end-1) = h(i+1,:,1:end-1) - h(i+1,:,2:end);
    dqminus(:,end) = h(i+1,:,end-1) - h(i+1,:,end);
    
    for z = 1:length(Zrange)
        for q = 1:length(Qrange)
            dz = 0;
            for k = 1:length(Zrange)
                dz = dz + G(z,k) * (1 - exp(-gamma * (Qrange(q) * (ceil(k/num_bins) ~= 2) * eta(z) + h(i+1,k,q) - h(i+1,z,q))));
            end
            
            % checking delta^- >= 1/kappa - 2*xi
            deltaminus = 1/gamma * log(1 + gamma/kappa) - xi*(1 + sign(Qrange(q))) + dqplus(z,q);
            deltaminus = max(deltaminus , 1/gamma * log(1 + gamma/kappa) - 2*xi);
            infgen_dKplus = exp(-kappa*deltaminus) * (1 - exp(-gamma * (xi + deltaminus + xi*sign(Qrange(q)) - dqplus(z,q))));
            
            % checking delta^+ >= 1/kappa - 2*xi
            deltaplus = 1/gamma * log(1 + gamma/kappa) - xi*(1 - sign(Qrange(q))) + dqminus(z,q);
            deltaplus = max(deltaplus , 1/gamma * log(1 + gamma/kappa) - 2*xi);
            infgen_dKminus = exp(-kappa*deltaplus) * (1 - exp(-gamma * (xi + deltaplus - xi*sign(Qrange(q)) - dqminus(z,q))));
                
            h(i,z,q) = h(i+1,z,q) + dt * 1/gamma * ( dz + ...
                    muplus(z)*infgen_dKplus + muminus(z)*infgen_dKminus );
        end
        
        h(i,z,Qmax+1) = 0;
        
        for q = 1:Qmax
            % indexing from 1 upward
            idx = Qmax+1+q;
            h(i,z,idx) = max(h(i,z,idx), h(i,z,idx-1) - xi + xi*sign(Qrange(idx)));
            % from end down to 1
            idx = 2*Qmax+1-q;
            h(i,z,idx) = max(h(i,z,idx), h(i,z,idx+1) - xi - xi*sign(Qrange(idx)));
            % from -1 downward
            idx = Qmax+1-q;
            h(i,z,idx) = max(h(i,z,idx), h(i,z,idx+1) - xi - xi*sign(Qrange(idx)));
            % from start up to -1
            idx = 1+q;
            h(i,z,idx) = max(h(i,z,idx), h(i,z,idx-1) - xi + xi*sign(Qrange(idx)));
        end
        
        h(i,z,Qmax+1) = 0;
    end
    waitbar( (T-i*dt) / T) 
end
close(progress)
end