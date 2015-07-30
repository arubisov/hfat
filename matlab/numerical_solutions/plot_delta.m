function [ ] = plot_delta( deltastar )

% plot the results for Delta
global T
global dt
global Qrange

x = dt:dt:T;

plotstep = 1;


for z = [1,3,5,6,8,10,11,13,15]

    figure('Name','Optimal Liquidation Posting Depth');
    hold on;
    
    minusfour = plot(x(1:plotstep:end),deltastar(1:plotstep:end,z,find(Qrange==-4)),'--g');
    minusthree = plot(x(1:plotstep:end),deltastar(1:plotstep:end,z,find(Qrange==-3)),'--m');
    minustwo = plot(x(1:plotstep:end),deltastar(1:plotstep:end,z,find(Qrange==-2)),'--r');
    minusone = plot(x(1:plotstep:end),deltastar(1:plotstep:end,z,find(Qrange==-1)),'--b');
    zero = plot(x(1:plotstep:end),deltastar(1:plotstep:end,z,find(Qrange==0)),'-k');
    one = plot(x(1:plotstep:end),deltastar(1:plotstep:end,z,find(Qrange==1)),'-b');
    two = plot(x(1:plotstep:end),deltastar(1:plotstep:end,z,find(Qrange==2)),'-r');
    three = plot(x(1:plotstep:end),deltastar(1:plotstep:end,z,find(Qrange==3)),'-m');
    four = plot(x(1:plotstep:end),deltastar(1:plotstep:end,z,find(Qrange==4)),'-g');

    hold off;
    set(gca,'fontsize',18);
    xlabel('Time', 'FontSize', 24, 'interpreter','latex');
    ylabel('Depth $\delta$', 'FontSize', 24, 'interpreter','latex');
    leg = legend( [minusfour, minusthree, minustwo, minusone, zero, one, two, three, four], ...
            { '$q=-4$', '$q=-3$', '$q=-2$', '$q=-1$', '$q=0$', '$q=1$', '$q=2$', '$q=3$', '$q=4$' } );
    set(leg, 'interpreter','latex','fontsize',16);
end


end

