%% Draw histograms for the estimated parameters

f = figure('Name','Estimated Parameters for Transition Matrix');
conf_ints = [1, 5, 10, 90, 95, 99];

for row = 1 : num_hidden_states
    for col = 1 : num_hidden_states
        
        data = reshape(param_TRANS(row,col,:),1,num_trials);
        subplot(num_hidden_states,num_hidden_states,(row-1)*num_hidden_states + col);
        [N,X] = hist(data);
        bar(X,N,0.1)
        xlim([0,1]);
        title(sprintf(['TRANS(' num2str(row) ',' num2str(col) ')']));
        xlabel('transition probability')
        ylabel('count')
        
        for conf = conf_ints
            x = prctile(data,conf);          
            hx = graph2d.constantline(x, 'LineStyle',':', 'Color',[1 0 0]);
            changedependvar(hx,'x');
        end
        
    end
end

g = figure('Name','Estimated Parameters for Emission Matrix');

for row = 1 : num_hidden_states
    for col = 1 : num_bins
        
        subplot(num_hidden_states,num_bins,(row-1)*num_bins + col);
        data = reshape(param_EMIS(row,col,:),1,num_trials);
        hist(data);
        xlim([0,1]);
        title(sprintf(['EMIS(' num2str(row) ',' num2str(col) ')']));
        xlabel('emission probability')
        ylabel('count')
        
        for conf = conf_ints
            x = prctile(data,conf);          
            hx = graph2d.constantline(x, 'LineStyle',':', 'Color',[1 0 0]);
            changedependvar(hx,'x');
        end

        
    end
end