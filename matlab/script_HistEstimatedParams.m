%% Draw histograms for the estimated parameters

f = figure('Name','Estimated Parameters for G');
conf_ints = [1, 5, 10, 90, 95, 99];

for row = 1 : 3
    for col = 1 : 3
        
        data = reshape(param_G(row,col,:),1,10000);
        subplot(3,3,(row-1)*3 + col);
        hist(data);
        title(sprintf(['G(' num2str(row) ',' num2str(col) ')']));
        xlabel('transition rate')
        ylabel('count')
        
        for conf = conf_ints
            x = prctile(data,conf);          
            hx = graph2d.constantline(x, 'LineStyle',':', 'Color',[1 0 0]);
            changedependvar(hx,'x');
        end
        
    end
end

g = figure('Name','Estimated Parameters for Lambda');

for row = 1 : 2
    for col = 1 : 3
        
        subplot(2,3,(row-1)*3 + col);
        data = reshape(param_lambda(row,col,:),1,10000);
        hist(data);
        if row ==1 
            title(sprintf('\\lambda^{+}_{%d}', col));         
        else
            title(sprintf('\\lambda^{-}_{%d}', col));   
        end
        
        for conf = conf_ints
            x = prctile(data,conf);          
            hx = graph2d.constantline(x, 'LineStyle',':', 'Color',[1 0 0]);
            changedependvar(hx,'x');
        end
        
        xlabel('intensity')
        ylabel('count')
        
    end
end
