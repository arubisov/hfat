function [ h, ctrl, optdelp, optdelm ] = dscr_h_case1_fzero_bak( data )
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
T = 50;                         % in s
dt = 1;                         % Markov Chain time increments

init_guess = 0.1;
options = optimset('Display','off');

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
    dqplus(:,1) = dqplus(:,2);
    
    % dq^- = h(t,z,q) - h(t,z,q+1)
    dqminus(:,1:end-1) = h(i+1,:,1:end-1) - h(i+1,:,2:end);
    dqminus(:,end) = dqminus(:,end-1);

    % aleph = h_{k+1}(j,q-1) + h_{k+1}(j,q+1) - 2*h_{k+1}(j,q)
    aleph(:,2:end-1) = h(i+1,:,1:end-2) + h(i+1,:,3:end) - 2*h(i+1,:,2:end-1);
    aleph(:,1) = aleph(:,2);
    aleph(:,end) = aleph(:,end-1);
    
    for z = 1:length(Zrange)

        for q = 1:length(Qrange)
            
            func = @(x) -x + 1/kappa + P(z,:)*eta ...
                -2*xi*(Qrange(q) >= 1) + P(z,:)*dqplus(:,q) ...
                -(1-exp(-muminus(z)*dt))*min(1,exp(-kappa*(1/kappa-P(z,:)*eta ...
                -2*xi*(Qrange(q) <= -1) + P(z,:)*dqminus(:,q) )) ...
                *exp(kappa*(1-exp(-muplus(z)*dt))*min(1,exp(-kappa*x)) ...
                *(2*xi*(Qrange(q) == 0) - P(z,:)*aleph(:,q)))) ...
                *(2*xi*(Qrange(q) == 0) - P(z,:)*aleph(:,q));
            guess1 = 1/kappa + P(z,:)*eta - 2*xi*(Qrange(q) >= 1) ...
                    + P(z,:)*dqplus(:,q);
            try
            dm1 = fzero(func, init_guess, options);
            catch
                disp('woops');
            end
            
            try
            func = @(x) -x + 1/kappa + P(z,:)*eta ...
                -2*xi*(Qrange(q) >= 0) + P(z,:)*dqplus(:,q+1)  ...
                -(1-exp(-muminus(z)*dt))*min(1,exp(-kappa*(1/kappa-P(z,:)*eta ...
                -2*xi*(Qrange(q) <= -2) + P(z,:)*dqminus(:,q+1) )) ...
                *exp(kappa*(1-exp(-muplus(z)*dt))*min(1,exp(-kappa*x)) ...
                *(2*xi*(Qrange(q) == -1) - P(z,:)*aleph(:,q+1)))) ...
                *(2*xi*(Qrange(q) == -1) - P(z,:)*aleph(:,q+1));
            guess2 = 1/kappa + P(z,:)*eta - 2*xi*(Qrange(q) >= 0) ...
                    + sum( P(z,:)*dqplus(:,q+1) );
            dm2 = fzero(func, init_guess, options);
            catch
            func = @(x) -x + 1/kappa + P(z,:)*eta ...
                -2*xi*(Qrange(q) >= 0) + P(z,:)*dqplus(:,q) ...
                -(1-exp(-muminus(z)*dt))*min(1,exp(-kappa*(1/kappa-P(z,:)*eta ...
                -2*xi*(Qrange(q) <= -2) + P(z,:)*dqminus(:,q) )) ...
                *exp(kappa*(1-exp(-muplus(z)*dt))*min(1,exp(-kappa*x)) ...
                *(2*xi*(Qrange(q) == -1) - P(z,:)*aleph(:,q)))) ...
                *(2*xi*(Qrange(q) == -1) - P(z,:)*aleph(:,q));
            guess2 = 1/kappa + P(z,:)*eta - 2*xi*(Qrange(q) >= 0) ...
                    + sum( P(z,:)*dqplus(:,q) );
            dm2 = fzero(func, init_guess, options);
            end

            try
            func = @(x) -x + 1/kappa + P(z,:)*eta ...
                -2*xi*(Qrange(q) >= 2) + P(z,:)*dqplus(:,q-1) ...
                -(1-exp(-muminus(z)*dt))*min(1,exp(-kappa*(1/kappa-P(z,:)*eta ...
                -2*xi*(Qrange(q) <= 0) + P(z,:)*dqminus(:,q-1) )) ...
                *exp(kappa*(1-exp(-muplus(z)*dt))*min(1,exp(-kappa*x)) ...
                *(2*xi*(Qrange(q) == 1) - P(z,:)*aleph(:,q-1)))) ...
                *(2*xi*(Qrange(q) == 1) - P(z,:)*aleph(:,q-1));
            guess3 = 1/kappa + P(z,:)*eta - 2*xi*(Qrange(q) >= 2) ...
                    + sum( P(z,:)*dqplus(:,q-1) );
            dm3 = fzero(func, init_guess, options);
            catch
            func = @(x) -x + 1/kappa + P(z,:)*eta ...
                -2*xi*(Qrange(q) >= 2) + P(z,:)*dqplus(:,q) ...
                -(1-exp(-muminus(z)*dt))*min(1,exp(-kappa*(1/kappa-P(z,:)*eta ...
                -2*xi*(Qrange(q) <= 0) + P(z,:)*dqminus(:,q) )) ...
                *exp(kappa*(1-exp(-muplus(z)*dt))*min(1,exp(-kappa*x)) ...
                *(2*xi*(Qrange(q) == 1) - P(z,:)*aleph(:,q)))) ...
                *(2*xi*(Qrange(q) == 1) - P(z,:)*aleph(:,q));
            guess3 = 1/kappa + P(z,:)*eta - 2*xi*(Qrange(q) >= 2) ...
                    + sum( P(z,:)*dqplus(:,q) );
            dm3 = fzero(func, init_guess, options);
            end
            
            if dm1 == dm2 == dm3, 
                fprintf('identical at %i %i %i\n',i,z,q); end;
            
            if isnan(dm1) && isnan(dm2) && isnan(dm3)
                fprintf('crisis with the dm at %i %i %i\n',i,z,q);
                dm1 = guess1;
                dm2 = guess2;
                dm3 = guess3;
            end
            
            pdm1 = (1 - exp(-muplus(z)*dt))*min(1,exp(-kappa*dm1));
            pdm2 = (1 - exp(-muplus(z)*dt))*min(1,exp(-kappa*dm2));
            pdm3 = (1 - exp(-muplus(z)*dt))*min(1,exp(-kappa*dm3));
            
            dp1 = 1/kappa - P(z,:)*eta ...
                -2*xi*(Qrange(q) <= -1) + P(z,:)*dqminus(:,q) ...
                -pdm1*(2*xi*(Qrange(q) == 0) - P(z,:)*aleph(:,q));
            
            try
            dp2 = 1/kappa - P(z,:)*eta ...
                -2*xi*(Qrange(q) <= -2) + P(z,:)*dqminus(:,q+1) ...
                -pdm2*(2*xi*(Qrange(q) == -1) - P(z,:)*aleph(:,q+1));
            catch
            dp2 = 1/kappa - P(z,:)*eta ...
                -2*xi*(Qrange(q) <= -2) + P(z,:)*dqminus(:,q) ...
                -pdm2*(2*xi*(Qrange(q) == -1) - P(z,:)*aleph(:,q));
            end

            try
            dp3 = 1/kappa - P(z,:)*eta ...
                -2*xi*(Qrange(q) <= 0) + P(z,:)*dqminus(:,q-1) ...
                -pdm3*(2*xi*(Qrange(q) == 1) - P(z,:)*aleph(:,q-1));
            catch
            dp3 = 1/kappa - P(z,:)*eta ...
                -2*xi*(Qrange(q) <= 0) + P(z,:)*dqminus(:,q) ...
                -pdm3*(2*xi*(Qrange(q) == 1) - P(z,:)*aleph(:,q));
            end
            
            pdp1 = (1 - exp(-muminus(z)*dt))*min(1,exp(-kappa*dp1));
            pdp2 = (1 - exp(-muminus(z)*dt))*min(1,exp(-kappa*dp2));
            pdp3 = (1 - exp(-muminus(z)*dt))*min(1,exp(-kappa*dp3));
            
            ctrl1 = Qrange(q)*P(z,:)*eta + 1/kappa*(pdp1 + pdm1) ...
                + pdp1*pdm1*(-2*xi*(Qrange(q) == 0) + (P(z,:)*aleph(:,q))) ...
                + P(z,:)*h(i+1,:,q)';

            try
            ctrl2 = (Qrange(q)+1)*P(z,:)*eta + 1/kappa*(pdp2 + pdm2) ...
                + pdp2*pdm2*(-2*xi*(Qrange(q) == -1) + (P(z,:)*aleph(:,q+1))) ...
                + P(z,:)*h(i+1,:,q+1)';
            catch
            ctrl2 = (Qrange(q)+1)*P(z,:)*eta + 1/kappa*(pdp2 + pdm2) ...
                + pdp2*pdm2*(-2*xi*(Qrange(q) == -1) + (P(z,:)*aleph(:,q))) ...
                + P(z,:)*h(i+1,:,q)';
            end

            try
            ctrl3 = (Qrange(q)-1)*P(z,:)*eta + 1/kappa*(pdp3 + pdm3) ...
                + pdp3*pdm3*(-2*xi*(Qrange(q) == 1) + (P(z,:)*aleph(:,q-1))) ...
                + P(z,:)*h(i+1,:,q-1)';
            catch
            ctrl3 = (Qrange(q)-1)*P(z,:)*eta + 1/kappa*(pdp3 + pdm3) ...
                + pdp3*pdm3*(-2*xi*(Qrange(q) == 1) + (P(z,:)*aleph(:,q))) ...
                + P(z,:)*h(i+1,:,q)';
            end            

            [h(i,z,q), ctrl(i,z,q)] = max([ctrl1, ctrl2, ctrl3]);

            
            switch ctrl(i,z,q)
                case 1
                    optdelp(i,z,q) = dp1;
                    optdelm(i,z,q) = dm1;
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
