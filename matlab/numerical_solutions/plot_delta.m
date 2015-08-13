function [ ] = plot_delta( deltastar, T, dt )

% plot the results for Delta

qzero = (size(deltastar, 3) - 1)/2 + 1;

x = dt:dt:T;

plotstep = 1/dt;

idx = [1:plotstep:numel(x)-100 numel(x)-99:1:numel(x)];


for z = [1,8,15]

    figure('Name','Optimal Liquidation Posting Depth');
    hold on;
    
    minusfour = plot(x(idx),deltastar(idx,z,qzero-4),'--g');
    minusthree = plot(x(idx),deltastar(idx,z,qzero-3),'--m');
    minustwo = plot(x(idx),deltastar(idx,z,qzero-2),'--r');
    minusone = plot(x(idx),deltastar(idx,z,qzero-1),'--b');
    zero = plot(x(idx),deltastar(idx,z,qzero),'-k');
    one = plot(x(idx),deltastar(idx,z,qzero+1),'-b');
    two = plot(x(idx),deltastar(idx,z,qzero+2),'-r');
    three = plot(x(idx),deltastar(idx,z,qzero+3),'-m');
    four = plot(x(idx),deltastar(idx,z,qzero+4),'-g');

    hold off;
    set(gca,'fontsize',18);
    xlabel('Time', 'FontSize', 24, 'interpreter','latex');
    ylabel('Depth $\delta$', 'FontSize', 24, 'interpreter','latex');
    leg = legend( [minusfour, minusthree, minustwo, minusone, zero, one, two, three, four], ...
            { '$q=-4$', '$q=-3$', '$q=-2$', '$q=-1$', '$q=0$', '$q=1$', '$q=2$', '$q=3$', '$q=4$' } );
    set(leg, 'interpreter','latex','fontsize',16);
    title(sprintf('Z=%d',z));
    %matlab2tikz(sprintf('dm_dscr_nFPC_z%d.tikz',z));
end


end

