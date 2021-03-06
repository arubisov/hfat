function [ h ] = cts_h_case1( phi, num_bins, Qmax, kappa, alpha, xi, ...
                              G, eta, muplus, muminus, T, dt  )
% Numerical solution to the continuous time Case 1 DPE ansatz h(t,z,q).
% Note that Case 3 is obtained by setting phi nonzero.
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
% Date  : 2015.07.13

Qrange = -Qmax:1:Qmax;
Zrange = 1:num_bins*3;

h = zeros(T/dt,length(Zrange),length(Qrange));

% Establish terminal condition h(T,z,q) = -alpha*q^2
% Face-lifting: never optimal to execute MO at maturity and pay xi+alpha*q
% per share; instead we liquidate immed. prior to maturity at a cost of xi
% per share. So left-hand limit at maturity is -xi*abs(q)
% ACTUALLY: i think we have to set it to zero...
% h(end, :, :) = repmat(-xi*abs(Qrange),num_bins*3,1);

%progress = waitbar(0, 'Calculating numerical solution...');

for i = round((T-dt)/dt):-1:1
    dqplus = zeros(length(Zrange),length(Qrange));
    dqminus = zeros(length(Zrange),length(Qrange));
    
    % dq^+ = h(t,z,q) - h(t,z,q-1)
    dqplus(:,2:end) = h(i+1,:,2:end) - h(i+1,:,1:end-1);
    dqplus(:,1) = dqplus(:,2);
    % dq^- = h(t,z,q) - h(t,z,q+1)
    dqminus(:,1:end-1) = h(i+1,:,1:end-1) - h(i+1,:,2:end);
    dqminus(:,end) = dqminus(:,end-1);
    
    % optimized like fucking crazy.
    dz = G*eta*Qrange + G*squeeze(h(i+1,:,:));
    
    for z = 1:length(Zrange)
        for q = 1:length(Qrange)
            % checking delta^- >= 1/kappa - 2*xi
            deltaminus = max( 0 , 1/kappa - 2*xi*(Qrange(q) >= 1) + dqplus(z,q) );
            infgen_dKplus = exp(-kappa*deltaminus) * (deltaminus + 2*xi*(Qrange(q) >= 1) - dqplus(z,q));
            
            % checking delta^+ >= 1/kappa - 2*xi
            deltaplus = max ( 0 , 1/kappa -2*xi*(Qrange(q) <= -1) + dqminus(z,q) );
            infgen_dKminus = exp(-kappa*deltaplus) * (deltaplus + 2*xi*(Qrange(q) <= -1) - dqminus(z,q));
                
            h(i,z,q) = h(i+1,z,q) + dt * (-phi*Qrange(q)*Qrange(q) + dz(z,q) + ...
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
    %waitbar( (T-i*dt) / T) 
end

%h(end, :, :) = repmat(-alpha*Qrange.*Qrange,num_bins*3,1);

%close(progress)
end