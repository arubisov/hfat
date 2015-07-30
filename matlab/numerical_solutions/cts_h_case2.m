function [ h ] = cts_h_case2( data )
% Numerical solution to the continuous time Case 2 DPE ansatz h(t,z,q).
%
% Master's Thesis
% Date  : 2015.07.26

global kappa
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
global avg_method
global dt_Z

% Parameters
dt_Z = 1000;                                %
num_bins = 5;                               %
avg_method = 5;                             %

[ binseries, pricechgseries, G, ~ ] = ...
    compute_G( data, dt_Z, num_bins, avg_method );
[ oneDseries ] = get1Dseries( binseries, pricechgseries, num_bins );
[ eta ] = compute_eta( oneDseries, pricechgseries, num_bins );
[ muplus, muminus ] = compute_mu( data, oneDseries, dt_Z, num_bins );
kappa = 100;
alpha = 0.01;
phi = 0.00001;
xi = 0.01;

% finite scheme setup
Qmax = 20;
Qrange = -Qmax:1:Qmax;
Zrange = 1:num_bins*3;
T = 100;                        % in s
dt = 0.01;                      % finite difference scheme: 0.01s increments

h = zeros(T/dt,length(Zrange),length(Qrange));

% Establish terminal condition h(T,z,q) = -alpha*q^2
% Face-lifting: never optimal to execute MO at maturity and pay xi+alpha*q
% per share; instead we liquidate immed. prior to maturity at a cost of xi
% per share. So left-hand limit at maturity is -xi*abs(q)
h(end, :, :) = repmat(-xi*abs(Qrange),num_bins*3,1);

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
                % dz = dz + G(z,k) * (Qrange(q) * (ceil(k/num_bins) ~= 2) * eta(z) + h(i+1,k,q) - h(i+1,z,q));
                dz = dz + G(z,k) * (1 - exp(-gamma * (Qrange(q) * eta(k) + h(i+1,k,q) - h(i+1,z,q))));
            end
            
            % checking delta^- >= 1/kappa - 2*xi
            deltaminus = 1/gamma * log(1 + gamma/kappa) - xi*(1 + sign(Qrange(q))) + dqplus(z,q);
            %deltaminus = max(deltaminus , 1/gamma * log(1 + gamma/kappa) - 2*xi);
            infgen_dKplus = exp(-kappa*deltaminus) * (1 - exp(-gamma * (xi + deltaminus + xi*sign(Qrange(q)) - dqplus(z,q))));
            
            % checking delta^+ >= 1/kappa - 2*xi
            deltaplus = 1/gamma * log(1 + gamma/kappa) - xi*(1 - sign(Qrange(q))) + dqminus(z,q);
            %deltaplus = max(deltaplus , 1/gamma * log(1 + gamma/kappa) - 2*xi);
            infgen_dKminus = exp(-kappa*deltaplus) * (1 - exp(-gamma * (xi + deltaplus - xi*sign(Qrange(q)) - dqminus(z,q))));
                
            h(i,z,q) = h(i+1,z,q) + dt * ( dz + ...
                    muplus(z)*infgen_dKplus + muminus(z)*infgen_dKminus );
        end
        
        % enforce condition at zero.
        h(i,z,Qmax+1) = 0;
        
        for q = 1:Qmax
            % indexing from 1 upward
            idx = Qmax+1+q;
            if h(i,z,idx) < h(i,z,idx-1), h(i,z,idx) = h(i,z,idx-1); end;
            if h(i,z,idx) > h(i,z,idx-1) + 2*xi, h(i,z,idx) = h(i,z,idx-1) + 2*xi; end;
            % from -1 downward
            idx = Qmax+1-q;
            if h(i,z,idx) < h(i,z,idx+1), h(i,z,idx) = h(i,z,idx+1); end;
            if h(i,z,idx) > h(i,z,idx+1) + 2*xi, h(i,z,idx) = h(i,z,idx+1) + 2*xi; end;
        end
    end
    waitbar( (T-i*dt) / T) 
end

h(end, :, :) = repmat(-alpha*Qrange.*Qrange,num_bins*3,1);

close(progress)
end