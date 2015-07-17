function [ ] = plot_delta( deltastar )

% plot the results for Delta
global T
global dt

x = dt:dt:T;

plotstep = 20;


for z = [1,3,5,6,8,10,11,13,15]

    figure('Name','Optimal Liquidation Posting Depth');
    hold on;
    
    minusfour = plot(x(1:plotstep:end),deltastar(1:plotstep:end,z,7),'--g');
    minusthree = plot(x(1:plotstep:end),deltastar(1:plotstep:end,z,8),'--m');
    minustwo = plot(x(1:plotstep:end),deltastar(1:plotstep:end,z,9),'--r');
    minusone = plot(x(1:plotstep:end),deltastar(1:plotstep:end,z,10),'--b');
    zero = plot(x(1:plotstep:end),deltastar(1:plotstep:end,z,11),'-k');
    one = plot(x(1:plotstep:end),deltastar(1:plotstep:end,z,12),'-b');
    two = plot(x(1:plotstep:end),deltastar(1:plotstep:end,z,13),'-r');
    three = plot(x(1:plotstep:end),deltastar(1:plotstep:end,z,14),'-m');
    four = plot(x(1:plotstep:end),deltastar(1:plotstep:end,z,15),'-g');

    hold off;
    set(gca,'fontsize',18);
    xlabel('Time', 'FontSize', 24, 'interpreter','latex');
    ylabel('Depth $\delta$', 'FontSize', 24, 'interpreter','latex');
    leg = legend( [minusfour, minusthree, minustwo, minusone, zero, one, two, three, four], ...
            { '$q=-4$', '$q=-3$', '$q=-2$', '$q=-1$', '$q=0$', '$q=1$', '$q=2$', '$q=3$', '$q=4$' } );
    set(leg, 'interpreter','latex','fontsize',16);
end


end

