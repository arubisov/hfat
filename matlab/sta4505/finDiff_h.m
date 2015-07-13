function [ hFunc ] = finDiff_h( )
% STA4505 Course Project - Ch12 on Order Imbalance
% Utilize a finite differences scheme to produce a solution for the 
% coupled system of non-linear PDEs. The optimal depth is solved using the
% resulting function.
%
% Date  : 2015.07.04

global kappa
global alpha
global phi
global Qmax
global Qrange
global Zmax
global Zrange
global T
global dt
global lambdaplus
global lambdaminus
global epsilonplus
global epsilonminus
global epsilonplustable
global epsilonminustable
global G

% Parameters
kappa = 100;
alpha = 0.01;
phi = 0.00001;
lambdaplus = [0.074;0.042;0.073;0.075;0.216];
lambdaminus = [0.856;0.123;0.048;0.027;0.025];
G = [-3.34, 2.34, 0.59, 0.28, 0.13;
     0.31, -0.93, 0.54, 0.01, 0.07;
     0.01, 0.26, -0.58, 0.30, 0.02;
     0.03, 0.01, 0.29, -0.56, 0.23;
     0.03, 0.03, 0.09, 0.74, -0.88];
epsilonplustable = [-0.03, 0, 0, 0, 0, 0;
                    -0.02, 0, 0, 0, 0, 0;
                    -0.01, 0, .05, .01, .01, 0;
                     0.00, 1, .86, .77, .78, .7;
                     0.01, 0, .09, .21, .20, .28;
                     0.02, 0, 0, 0, 0, .02;
                     0.03, 0, 0, 0, 0, 0];
epsilonminustable = [-0.03, 0, 0, 0, .01, .03;
                    -0.02, .01, 0, .01, .02, .01;
                    -0.01, .21, .36, .36, .28, .21;
                     0.00, .79, .64, .63, .69, .75;
                     0.01, 0, 0, 0, 0, 0;
                     0.02, 0, 0, 0, 0, 0;
                     0.03, 0, 0, 0, 0, 0];
% normalize any decimal rounding errors in the above tables.
epsilonplustable(:,2:6) = epsilonplustable(:,2:6)./repmat(sum(epsilonplustable(:,2:6),1),7,1);
epsilonminustable(:,2:6) = epsilonminustable(:,2:6)./repmat(sum(epsilonminustable(:,2:6),1),7,1);
% compute expected values
epsilonplus = sum(repmat(epsilonplustable(:,1),1,5).*epsilonplustable(:,2:6),1)';
epsilonminus = sum(repmat(epsilonminustable(:,1),1,5).*epsilonminustable(:,2:6),1)';
% precompute mu(z)
mu = lambdaplus.*epsilonplus + lambdaminus.*epsilonminus;

% finite scheme setup
Qmax = 20;
Qrange = -Qmax:1:Qmax;
Zmax = 2;
Zrange = -Zmax:1:Zmax;
T = 300.0;
dt = 0.02;

hFunc = zeros(T/dt,length(Zrange),length(Qrange));

% Establish terminal condition h(T,z,q) = -alpha*q^2
hFunc(end, :, :) = repmat(-alpha*Qrange.*Qrange,5,1);

for i = round((T-dt)/dt):-1:1
    dq = zeros(length(Zrange),length(Qrange));
    
    dq(:,2:end) = hFunc(i+1,:,2:end) - hFunc(i+1,:,1:end-1);
    dq(:,1) = hFunc(i+1,:,2) - hFunc(i+1,:,1);
    
    for z = 1:length(Zrange)
        for q = length(Qrange):-1:1
            dz = 0;
            for k = 1:length(Zrange)
                dz = dz + G(z,k) * (hFunc(i+1,k,q) - hFunc(i+1,z,q));
            end
            
            if -dq(z,q) >= 1/kappa + epsilonplus(z)
                hFunc(i,z,q) = hFunc(i+1,z,q) + dt*(mu(z)*Qrange(q) ...
                                    - phi*Qrange(q)*Qrange(q) + dz ...
                                    - lambdaplus(z) * (dq(z,q) ...
                                        + epsilonplus(z)));                      
            else
                hFunc(i,z,q) = hFunc(i+1,z,q) + dt*(mu(z)*Qrange(q) ...
                                    - phi*Qrange(q)*Qrange(q)  + dz ...
                                    + lambdaplus(z) * (1/kappa) * exp( ...
                                        - kappa * (1/kappa + dq(z,q) ...
                                        + epsilonplus(z))));                
            end

        end
        
        for q = Qmax+1
            % Enforce boundary condition h(t,z,0) = 0
            hFunc(i,z,q) = 0;
        end
    end
end