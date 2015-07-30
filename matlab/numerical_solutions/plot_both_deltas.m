function [ ] = plot_both_deltas( deltaplus, deltaminus )

% plot the results for Delta
global T
global dt
global Qrange

x = dt:dt:T;

plotstep = 1;


for z = [1,3,5,6,8,10,11,13,15]

    figure('Name','Optimal Liquidation Posting Depth');
    hold on;
    
    zeroplus = plot(x(1:plotstep:end),deltaplus(1:plotstep:end,z,find(Qrange==0)),'-k');
    zerominus = plot(x(1:plotstep:end),deltaminus(1:plotstep:end,z,find(Qrange==0)),'--k');
    oneplus = plot(x(1:plotstep:end),deltaplus(1:plotstep:end,z,find(Qrange==1)),'-b');
    oneminus = plot(x(1:plotstep:end),deltaminus(1:plotstep:end,z,find(Qrange==1)),'--b');
    twoplus = plot(x(1:plotstep:end),deltaplus(1:plotstep:end,z,find(Qrange==2)),'-r');
    twominus = plot(x(1:plotstep:end),deltaminus(1:plotstep:end,z,find(Qrange==2)),'--r');

    hold off;
    set(gca,'fontsize',18);
    xlabel('Time', 'FontSize', 24, 'interpreter','latex');
    ylabel('Depth $\delta$', 'FontSize', 24, 'interpreter','latex');
    leg = legend( [zeroplus, zerominus, oneplus, oneminus, twoplus, twominus], ...
            { '$\delta^+, q=0$', '$\delta^-, q=0$', ...
              '$\delta^+, q=1$', '$\delta^-, q=1$', ...
              '$\delta^+, q=2$', '$\delta^-, q=2$' } );
    set(leg, 'interpreter','latex','fontsize',16);
end


end

