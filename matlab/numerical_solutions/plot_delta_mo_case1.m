function [ ] = plot_delta( deltastar, q )

% plot the results for Delta
global T
global dt
global xi
global Qrange

x = dt:dt:T;

plotstep = 20;

% adjust for q in range. 
q = q + 11; % or find in Qrange

delta = zeros(length(x(1:plotstep:end)));

figure('Name','Optimal Liquidation Posting Depth');
hold on;

for z = [1,8,15]
	for t = x(1:plotstep:end)
		while deltastar(t,z,q+1) - deltastar(t,z,q) = 2*xi*(q >= 0)
		    plt_b_fill = plot(t, q, '-ok', 'markerfacecolor','b', 'linewidth', 1  );
			q = q+1;
		end
		while deltastar(t,z,q-1) - deltastar(t,z,q) = 2*xi*(q <= 0)
		    plt_b_nofill = plot(t, q, '-ok', 'linewidth', 1  );
			q = q-1;
		end
		delta = deltastar(t,z,q);
	end
	
	if z == 1
	    z1val = plot(x(1:plotstep:end),delta),'-g');		
	elseif z == 8
    	z8val = plot(x(1:plotstep:end),delta),'-m');
	elseif z == 15
	    z15val = plot(x(1:plotstep:end),delta),'-r');
	end
end

hold off;
set(gca,'fontsize',18);
xlabel('Time', 'FontSize', 24, 'interpreter','latex');
ylabel('Depth $\delta$', 'FontSize', 24, 'interpreter','latex');
leg = legend( [z1val, z8val, z15val], ...
        { '$z=1$', '$z=8$', '$z=15$' } );
set(leg, 'interpreter','latex','fontsize',16);

end
