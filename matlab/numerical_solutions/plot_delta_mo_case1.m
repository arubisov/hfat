function [ ] = plot_delta_mo_case1( deltastar, h, qinit )

% plot the results for Delta
global T
global dt
global kappa
global xi
global Qrange

x = dt:dt:T;

plotstep = 20;

% adjust for q in range. 
q = find(Qrange==qinit,1); % or find in Qrange

delta = zeros(length(x(1:plotstep:end)),1);

figure('Name','Optimal Liquidation Posting Depth');
hold on;

for z = 1
    for t = round(x(1:plotstep:end)/dt)
        while h(t,z,q+10+1) - h(t,z,q+10) == 2*xi*(Qrange(q) >= 0)
            plt_b_fill = plot(x(t), deltastar(t,z,q), '-og', 'markerfacecolor','g', 'linewidth', 1  );
            q = q+1;
        end
        while h(t,z,q+10-1) - h(t,z,q+10) == 2*xi*(Qrange(q) <= 0)
            plt_b_nofill = plot(x(t), deltastar(t,z,q), '-og', 'linewidth', 1  );
            q = q-1;
        end
        delta(1/plotstep*(t-1) + 1) = deltastar(t,z,q);
    end
    
    z1val = plot(x(1:plotstep:end),delta,'-g');
end

q = find(Qrange==qinit,1); % or find in Qrange

for z = 8
    for t = round(x(1:plotstep:end)/dt)
        if t == 1
            t = 1;
        end
        while h(t,z,q+10+1) - h(t,z,q+10) == 2*xi*(Qrange(q) >= 0)
            plt_b_fill = plot(x(t), deltastar(t,z,q), '-om', 'markerfacecolor','m', 'linewidth', 1  );
            q = q+1;
        end
        while h(t,z,q+10-1) - h(t,z,q+10) == 2*xi*(Qrange(q) <= 0)
            plt_b_nofill = plot(x(t), deltastar(t,z,q), '-om', 'linewidth', 1  );
            q = q-1;
        end
        delta(1/plotstep*(t-1) + 1) = deltastar(t,z,q);
    end
    
    z8val = plot(x(1:plotstep:end),delta,'-m');
end

q = find(Qrange==qinit,1); % or find in Qrange

for z = 15
    for t = round(x(1:plotstep:end)/dt)
        while h(t,z,q+10+1) - h(t,z,q+10) == 2*xi*(Qrange(q) >= 0)
            plt_b_fill = plot(x(t), deltastar(t,z,q), '-or', 'markerfacecolor','r', 'linewidth', 1  );
            q = q+1;
        end
        while h(t,z,q+10-1) - h(t,z,q+10) == 2*xi*(Qrange(q) <= 0)
            plt_b_nofill = plot(x(t), deltastar(t,z,q), '-or', 'linewidth', 1  );
            q = q-1;
        end
        delta(1/plotstep*(t-1) + 1) = deltastar(t,z,q);
    end

    z15val = plot(x(1:plotstep:end),delta,'-r');
end


hold off;
set(gca,'fontsize',18);
xlabel('Time', 'FontSize', 24, 'interpreter','latex');
ylabel('Depth $\delta$', 'FontSize', 24, 'interpreter','latex');
leg = legend( [z1val, z8val, z15val], ...
        { '$z=1$', '$z=8$', '$z=15$' } );
set(leg, 'interpreter','latex','fontsize',16);

end
