function [ h, ctrl, optdelp, optdelm ] = dscr_h_case1( data )
% Numerical solution to the discrete time Case 1 DPE ansatz h(t,z,q).
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
% Date  : 2015.07.26
%
% TODO: account for boundary conditions when q = 1 or Q = end and we're trying to access q-1 or q+1

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
P = gentoprob(G);
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
T = 3;                        % in s
dt = 1;                         % Markov Chain time increments

x = sym('x');

h = zeros(T/dt,length(Zrange),length(Qrange));
ctrl = zeros(T/dt,length(Zrange),length(Qrange));
optdelp = zeros(T/dt,length(Zrange),length(Qrange));
optdelm = zeros(T/dt,length(Zrange),length(Qrange));

% Establish terminal condition h(T,z,q) = -alpha*q^2
% Face-lifting: never optimal to execute MO at maturity and pay xi+alpha*q
% per share; instead we liquidate immed. prior to maturity at a cost of xi
% per share. So at T-1, we have a penultimate terminal condition of
% h(T-1,z,q) = -xi*abs(q)
h(end, :, :) = repmat(-alpha*Qrange.*Qrange,num_bins*3,1);
h(end-1, :, :) = repmat(-xi*abs(Qrange),num_bins*3,1);

progress = waitbar(0, 'Calculating numerical solution...');

for i = round((T-2*dt)/dt):-1:1
    dqplus = zeros(length(Zrange),length(Qrange));
    dqminus = zeros(length(Zrange),length(Qrange));
    aleph = zeros(length(Zrange),length(Qrange));
    
    % dq^+ = h(t,z,q) - h(t,z,q-1)
    dqplus(:,2:end) = h(i+1,:,2:end) - h(i+1,:,1:end-1);
    dqplus(:,1) = h(i+1,:,2) - h(i+1,:,1);
    
    % dq^- = h(t,z,q) - h(t,z,q+1)
    dqminus(:,1:end-1) = h(i+1,:,1:end-1) - h(i+1,:,2:end);
    dqminus(:,end) = h(i+1,:,end-1) - h(i+1,:,end);

    % aleph = h_{k+1}(j,q-1) + h_{k+1}(j,q+1) - 2*h_{k+1}(j,q)
    aleph(:,2:end-1) = h(i+1,:,1:end-2) + h(i+1,:,3:end) - 2*h(i+1,:,2:end-1);
    aleph(:,1) = h(i+1,:,2) - h(i+1,:,1);
    aleph(:,end) = h(i+1,:,end-1) - h(i+1,:,end);
    
    for z = 1:length(Zrange)

        for q = 1:length(Qrange)

            dm1 = double(vpasolve( 0 == -x + 1/kappa + eta(z) ...
                -2*xi*(Qrange(q) >= 1) + sum( P(z,:)*dqplus(:,q) ) ...
                -(1-exp(muminus(z)*dt))*exp(-kappa*(1/kappa-eta(z) ...
                -2*xi*(Qrange(q) <= -1) + sum( P(z,:)*dqminus(:,q) ))) ...
                *exp(kappa*(1-exp(muplus(z)*dt))*exp(-kappa*x) ...
                *(2*xi*(Qrange(q) == 0) - sum( P(z,:)*aleph(:,q)))) ...
                *(2*xi*(Qrange(q) == 0) - sum( P(z,:)*aleph(:,q))) , x, 0.01 ));
            
            try
            dm2 = double(vpasolve( 0 == -x + 1/kappa + eta(z) ...
                -2*xi*(Qrange(q) >= 0) + sum( P(z,:)*dqplus(:,q+1) ) ...
                -(1-exp(muminus(z)*dt))*exp(-kappa*(1/kappa-eta(z) ...
                -2*xi*(Qrange(q) <= -2) + sum( P(z,:)*dqminus(:,q+1) ))) ...
                *exp(kappa*(1-exp(muplus(z)*dt))*exp(-kappa*x) ...
                *(2*xi*(Qrange(q) == -1) - sum( P(z,:)*aleph(:,q+1)))) ...
                *(2*xi*(Qrange(q) == -1) - sum( P(z,:)*aleph(:,q+1))) , x, 0.01 ));
            catch
            dm2 = double(vpasolve( 0 == -x + 1/kappa + eta(z) ...
                -2*xi*(Qrange(q) >= 0) + sum( P(z,:)*dqplus(:,q) ) ...
                -(1-exp(muminus(z)*dt))*exp(-kappa*(1/kappa-eta(z) ...
                -2*xi*(Qrange(q) <= -2) + sum( P(z,:)*dqminus(:,q) ))) ...
                *exp(kappa*(1-exp(muplus(z)*dt))*exp(-kappa*x) ...
                *(2*xi*(Qrange(q) == -1) - sum( P(z,:)*aleph(:,q)))) ...
                *(2*xi*(Qrange(q) == -1) - sum( P(z,:)*aleph(:,q))) , x, 0.01 ));
            end

            try
            dm3 = double(vpasolve( 0 == -x + 1/kappa + eta(z) ...
                -2*xi*(Qrange(q) >= 2) + sum( P(z,:)*dqplus(:,q) ) ...
                -(1-exp(muminus(z)*dt))*exp(-kappa*(1/kappa-eta(z) ...
                -2*xi*(Qrange(q) <= 0) + sum( P(z,:)*dqminus(:,q) ))) ...
                *exp(kappa*(1-exp(muplus(z)*dt))*exp(-kappa*x) ...
                *(2*xi*(Qrange(q) == 1) - sum( P(z,:)*aleph(:,q)))) ...
                *(2*xi*(Qrange(q) == 1) - sum( P(z,:)*aleph(:,q))) , x, 0.01 ));
            catch
            dm3 = double(vpasolve( 0 == -x + 1/kappa + eta(z) ...
                -2*xi*(Qrange(q) >= 2) + sum( P(z,:)*dqplus(:,q-1) ) ...
                -(1-exp(muminus(z)*dt))*exp(-kappa*(1/kappa-eta(z) ...
                -2*xi*(Qrange(q) <= 0) + sum( P(z,:)*dqminus(:,q-1) ))) ...
                *exp(kappa*(1-exp(muplus(z)*dt))*exp(-kappa*x) ...
                *(2*xi*(Qrange(q) == 1) - sum( P(z,:)*aleph(:,q-1)))) ...
                *(2*xi*(Qrange(q) == 1) - sum( P(z,:)*aleph(:,q-1))) , x, 0.01 ));
            end

            try
            dp1 = double(vpasolve( 0 == -x + 1/kappa - eta(z) ...
                -2*xi*(Qrange(q) <= -1) + sum( P(z,:)*dqminus(:,q) ) ...
                -(1-exp(muplus(z)*dt))*exp(-kappa*(1/kappa+eta(z) ...
                -2*xi*(Qrange(q) >= 1) + sum( P(z,:)*dqplus(:,q) ))) ...
                *exp(kappa*(1-exp(muminus(z)*dt))*exp(-kappa*x) ...
                *(2*xi*(Qrange(q) == 0) - sum( P(z,:)*aleph(:,q)))) ...
                *(2*xi*(Qrange(q) == 0) - sum( P(z,:)*aleph(:,q))) , x, 0.01 ));
            catch
                disp([i, z, q]);
            end

            try
            dp2 = double(vpasolve( 0 == -x + 1/kappa - eta(z) ...
                -2*xi*(Qrange(q) <= -2) + sum( P(z,:)*dqminus(:,q+1) ) ...
                -(1-exp(muplus(z)*dt))*exp(-kappa*(1/kappa+eta(z) ...
                -2*xi*(Qrange(q) >= 0) + sum( P(z,:)*dqplus(:,q+1) ))) ...
                *exp(kappa*(1-exp(muminus(z)*dt))*exp(-kappa*x) ...
                *(2*xi*(Qrange(q) == -1) - sum( P(z,:)*aleph(:,q+1)))) ...
                *(2*xi*(Qrange(q) == -1) - sum( P(z,:)*aleph(:,q+1))) , x, 0.01 ));
            catch
            dp2 = double(vpasolve( 0 == -x + 1/kappa - eta(z) ...
                -2*xi*(Qrange(q) <= -2) + sum( P(z,:)*dqminus(:,q) ) ...
                -(1-exp(muplus(z)*dt))*exp(-kappa*(1/kappa+eta(z) ...
                -2*xi*(Qrange(q) >= 0) + sum( P(z,:)*dqplus(:,q) ))) ...
                *exp(kappa*(1-exp(muminus(z)*dt))*exp(-kappa*x) ...
                *(2*xi*(Qrange(q) == -1) - sum( P(z,:)*aleph(:,q)))) ...
                *(2*xi*(Qrange(q) == -1) - sum( P(z,:)*aleph(:,q))) , x, 0.01 ));
            end

            try
            dp3 = double(vpasolve( 0 == -x + 1/kappa - eta(z) ...
                -2*xi*(Qrange(q) <= 0) + sum( P(z,:)*dqminus(:,q-1) ) ...
                -(1-exp(muplus(z)*dt))*exp(-kappa*(1/kappa+eta(z) ...
                -2*xi*(Qrange(q) >= 2) + sum( P(z,:)*dqplus(:,q-1) ))) ...
                *exp(kappa*(1-exp(muminus(z)*dt))*exp(-kappa*x) ...
                *(2*xi*(Qrange(q) == 1) - sum( P(z,:)*aleph(:,q-1)))) ...
                *(2*xi*(Qrange(q) == 1) - sum( P(z,:)*aleph(:,q-1))) , x, 0.01 ));
            catch
            dp3 = double(vpasolve( 0 == -x + 1/kappa - eta(z) ...
                -2*xi*(Qrange(q) <= 0) + sum( P(z,:)*dqminus(:,q) ) ...
                -(1-exp(muplus(z)*dt))*exp(-kappa*(1/kappa+eta(z) ...
                -2*xi*(Qrange(q) >= 2) + sum( P(z,:)*dqplus(:,q) ))) ...
                *exp(kappa*(1-exp(muminus(z)*dt))*exp(-kappa*x) ...
                *(2*xi*(Qrange(q) == 1) - sum( P(z,:)*aleph(:,q)))) ...
                *(2*xi*(Qrange(q) == 1) - sum( P(z,:)*aleph(:,q))) , x, 0.01 ));
            end
            
            if isempty(dp1), dp1 = -pi; end;
            if isempty(dp2), dp2 = -pi; end;
            if isempty(dp3), dp3 = -pi; end;
            if isempty(dm1), dm1 = -pi; end;
            if isempty(dm2), dm2 = -pi; end;
            if isempty(dm3), dm3 = -pi; end;

            pdp1 = (1 - exp(-muminus(z)*dt))*exp(-kappa*dp1);
            pdm1 = (1 - exp(-muplus(z)*dt))*exp(-kappa*dm1);

            pdp2 = (1 - exp(-muminus(z)*dt))*exp(-kappa*dp2);
            pdm2 = (1 - exp(-muplus(z)*dt))*exp(-kappa*dm2);

            pdp3 = (1 - exp(-muminus(z)*dt))*exp(-kappa*dp3);
            pdm3 = (1 - exp(-muplus(z)*dt))*exp(-kappa*dm3);

            ctrl1 = Qrange(q)*eta(z) + 1/kappa*(pdp1 + pdm1) ...
                + pdp1*pdm1*(-2*xi*(Qrange(q) == 0) + (P(z,:)*aleph(:,q))) ...
                + P(z,:)*h(i+1,:,q)';

            try
            ctrl2 = (Qrange(q)+1)*eta(z) + 1/kappa*(pdp2 + pdm2) ...
                + pdp2*pdm2*(-2*xi*(Qrange(q) == -1) + (P(z,:)*aleph(:,q+1))) ...
                + P(z,:)*h(i+1,:,q+1)';
            catch
            ctrl2 = (Qrange(q)+1)*eta(z) + 1/kappa*(pdp2 + pdm2) ...
                + pdp2*pdm2*(-2*xi*(Qrange(q) == -1) + (P(z,:)*aleph(:,q))) ...
                + P(z,:)*h(i+1,:,q)';
            end

            try
            ctrl3 = (Qrange(q)-1)*eta(z) + 1/kappa*(pdp3 + pdm3) ...
                + pdp3*pdm3*(-2*xi*(Qrange(q) == 1) + (P(z,:)*aleph(:,q-1))) ...
                + P(z,:)*h(i+1,:,q-1)';
            catch
            ctrl3 = (Qrange(q)-1)*eta(z) + 1/kappa*(pdp3 + pdm3) ...
                + pdp3*pdm3*(-2*xi*(Qrange(q) == 1) + (P(z,:)*aleph(:,q))) ...
                + P(z,:)*h(i+1,:,q)';
            end            

            [h(i,z,q), ctrl(i,z,q)] = max([ctrl1, ctrl2, ctrl3]);

            switch ctrl(i,z,q)
                case 1
                    try
                    optdelp(i,z,q) = dp1;
                    optdelm(i,z,q) = dm1;
                    catch
                        disp('error');
                    end
                case 2
                    optdelp(i,z,q) = dp2;
                    optdelm(i,z,q) = dm2;
                case 3
                    optdelp(i,z,q) = dp3;
                    optdelm(i,z,q) = dm3;
            end
        end
        
        % enforce condition at zero.
        h(i,z,Qmax+1) = 0;
        
    end
    waitbar( (T-i*dt) / T) 
end
close(progress)
end
