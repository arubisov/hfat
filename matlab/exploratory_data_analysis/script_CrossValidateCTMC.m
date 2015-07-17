%% Cross-validate a CTMC calibration.

num_bins = 5;
dt = 100;

fprintf('*** Beginning Cross-Validation ***\n');
fprintf('Number of bins = %d, averaging time (ms) = %d\n', num_bins, dt);

if exist('data','var') == 0
    datafile = './data/ORCL_20130515.mat';
    load(datafile);
    fprintf('Loaded data: %s\n', datafile);
end

[G, ~] = estimatemodelparameters(data, dt, num_bins);


fprintf('CTMC generator matrix G:\n');
disp(G);

% determine number of timesteps to converge to invariant distribution
errTol = 1e-05;
convergence = false;
num_steps = 1;
next_A = expm(G*dt/1000*num_steps);

while convergence == false
    num_steps = num_steps + 1;
    prev_A = next_A;
    next_A = expm(G*dt/1000*num_steps);
    absError = abs(next_A(:) - prev_A(:));
    convergence = all(absError < errTol);
end



fprintf('Calculated power n such that A^n converges: %d\n', num_steps);
fprintf('Stationary distribution A^%d:\n', num_steps);
disp(next_A);

% begin cross-validation...
[t, binseries] = getbintimeseries(data, dt, num_bins);

% determine what size of interval we therefore need to remove. 
interval_size = 100*num_steps;

% TODO: try comparing the matrix A instead of G
% TODO: variable window size, sliding intervals.
% TODO: compute absolute error, at the end divide through by individual
% elements to get relative error. 

num_runs = floor(size(t,2) / interval_size);

fprintf('Corresponding timestep size of omitted interval: %d steps, or %0.1f of entire series.\n', interval_size, round(interval_size/size(binseries,1)*1000)/10);

cross_validation_error_sum = 0;
error_matrix = zeros(num_bins);
for run = 1 : num_runs
    
    % we're going to iteratively remove a section (of size 'num_steps') of the 
    % time series, and separately produce generator matrices G for both the
    % 'remaining' series and the 'removed' series.

    % estimate CTMC generator matrix G for the remaining section. 
    G_remaining = zeros(num_bins);
    
    if run > 1
        section_one = binseries(1:(run-1)*interval_size);
    else
        section_one = NaN;
    end
    
    if run*interval_size < size(binseries,1)
        section_two = binseries(run*interval_size + 1:end);
    else
        section_two = NaN;
    end
    section_removed = binseries((run-1)*interval_size + 1 : run*interval_size);

    % count number of regime switches
    series = section_one;
    for i = 2 : length(series)
        if series(i-1) == series(i), continue; end;

        G_remaining(series(i-1), series(i)) = G_remaining(series(i-1), series(i)) + 1;    
    end
    series = section_two;
    for i = 2 : length(series)
        if series(i-1) == series(i), continue; end;

        G_remaining(series(i-1), series(i)) = G_remaining(series(i-1), series(i)) + 1;    
    end

    for bin = 1 : num_bins
        G_remaining(bin,:) = G_remaining(bin,:) / ((sum(section_one == bin) + sum(section_two == bin)) * dt / 1000);
        G_remaining(bin,bin) = -sum(G_remaining(bin,:));
    end
    
%     fprintf('Remaining section %d. Generator matrix G:\n', run);
%     disp(G_remaining);
 
    % estimate CTMC generator matrix G for the removed section. 
    G_removed = zeros(num_bins);
    
     % count number of regime switches
    series = section_removed;
    for i = 2 : length(series)
        if series(i-1) == series(i), continue; end;

        G_removed(series(i-1), series(i)) = G_removed(series(i-1), series(i)) + 1;    
    end

    for bin = 1 : num_bins
        if sum(series == bin) == 0
            G_removed(bin,:) = 0;
        else
            G_removed(bin,:) = G_removed(bin,:) / (sum(series == bin) * dt / 1000);
            G_removed(bin,bin) = -sum(G_removed(bin,:));
        end
    end
    
%     fprintf('Omitted section %d. Generator matrix G:\n', run);
%     disp(G_removed); 
    
    this_error_matrix = (G_remaining - G_removed).^2;
    this_run_error_sqrd = 1/((num_bins^2)^2) * (sum(sum(this_error_matrix,2),1));
    cross_validation_error_sum = cross_validation_error_sum + this_run_error_sqrd;
    
    error_matrix = error_matrix + (1 - G_removed./G_remaining).^2;
    
    
end

cross_validation_error_sum = sqrt(cross_validation_error_sum / num_runs);
error_matrix = sqrt(1/num_runs * error_matrix);


fprintf('Total error: %0.6f\n', cross_validation_error_sum);
fprintf('Per cell in G, error ranges between %d%% and %d%% of the entry values.\n', round(min(min(error_matrix))*100), round(max(max(error_matrix))*100));

% fprintf('Aggregate error matrix:\n');
% disp(error_matrix);