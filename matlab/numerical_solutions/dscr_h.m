function [ h, optdelp, optdelm ] = dscr_h( num_bins, Qmax, kappa, alpha, xi, ...
                              P, eta, muplus, muminus, T, dt_Z)
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
% Date  : 2015.07.28

% finite scheme setup
Qrange = -Qmax:1:Qmax;
Zrange = 1:num_bins*3;

init_guess = 0.01;
options = optimset('Display','off');

h = zeros(T/dt_Z,length(Zrange),length(Qrange));
optdelp = zeros(T/dt_Z,length(Zrange),length(Qrange));
optdelm = zeros(T/dt_Z,length(Zrange),length(Qrange));

% Establish terminal condition h(T,z,q) = -alpha*q^2
% Face-lifting: never optimal to execute MO at maturity and pay xi+alpha*q
% per share; instead we liquidate immed. prior to maturity at a cost of xi
% per share. So at T-1, we have a penultimate terminal condition of
% h(T-1,z,q) = -xi*abs(q)
% h(end, :, :) = repmat(-alpha*Qrange.*Qrange,num_bins*3,1);
% h(end-1, :, :) = repmat(-xi*abs(Qrange),num_bins*3,1);

%progress = waitbar(0, 'Calculating numerical solution...');

for i = round((T-2*dt_Z)/dt_Z):-1:1
    
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
            probdelm = @(x) min( 1 , exp( -kappa*x ) );
            probdelp = @(x) (1 - exp(-muminus(z)*dt_Z) ) ...
                *min( 1 , exp( -kappa * ( 1/kappa - P(z,:)*eta ...
                -2*xi*(Qrange(q) <= -1) + P(z,:)*dqminus(:,q) ) ) ...
                *exp( kappa*( 1 - exp( -muplus(z)*dt_Z) ) * probdelm(x) ...
                *(2*xi*(Qrange(q) == 0) - P(z,:)*aleph(:,q) ) ) );
            func = @(x) -x + 1/kappa + P(z,:)*eta ...
                -2*xi*(Qrange(q) >= 1) + P(z,:)*dqplus(:,q) ...
                -probdelp(x)*(2*xi*(Qrange(q) == 0) - P(z,:)*aleph(:,q));
            
            guess1 = 1/kappa + P(z,:)*eta - 2*xi*(Qrange(q) >= 1) + P(z,:)*dqplus(:,q);
            
            try
            dm1 = fzero(func, guess1, options);
            catch
                disp('woops');
            end
            
            if isnan(dm1), fprintf('crisis with the dm at %i %i %i\n',i,z,q); end
            
            dm1 = max(dm1, 0);
            
            pdm1 = (1 - exp(-muplus(z)*dt_Z))*exp(-kappa*dm1);
           
            dp1 = max( 0 , 1/kappa - P(z,:)*eta ...
                -2*xi*(Qrange(q) <= -1) + P(z,:)*dqminus(:,q) ...
                -pdm1*(2*xi*(Qrange(q) == 0) - P(z,:)*aleph(:,q)) );
            
            pdp1 = (1 - exp(-muminus(z)*dt_Z))*exp(-kappa*dp1);
            
            h(i,z,q) = Qrange(q)*P(z,:)*eta + 1/kappa*(pdp1 + pdm1) ...
                + pdp1*pdm1*(-2*xi*(Qrange(q) == 0) + P(z,:)*aleph(:,q)) ...
                + P(z,:)*h(i+1,:,q)';

            optdelp(i,z,q) = dp1;
            optdelm(i,z,q) = dm1;
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
    %waitbar( (T-i*dt_Z) / T) 
end
%close(progress)
end