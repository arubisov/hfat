%%% Run HMM training repeatedly.

tic;

[t, binseries] = getbintimeseries();

num_hidden_states = 3;
num_bins = 3;

num_trials = 100;

param_TRANS = zeros(num_hidden_states,num_hidden_states,num_trials);
param_EMIS = zeros(num_hidden_states,num_bins,num_trials);  

tol = 1e-1;

h = waitbar(0,'Training Hidden Markov Model...');

good_estimates = 0;

for k = 1 : num_trials
    waitbar(k / num_trials);

    %TRANS_GUESS = rand(num_hidden_states,num_hidden_states);
    %div = sum(TRANS_GUESS,2);
    %div = repmat(div,1,num_hidden_states);
    %TRANS_GUESS = TRANS_GUESS ./ div;
    
    u = 0.1*k;
    TRANS_GUESS = .001*k/(num_hidden_states - 1) * ones(num_hidden_states) + ((1-0.001*k) - 0.001*k/(num_hidden_states - 1))*eye(num_hidden_states);

%     EMIS_GUESS = rand(num_hidden_states,num_bins);
%     div = sum(EMIS_GUESS,2);
%     div = repmat(div,1,num_bins);
%     EMIS_GUESS = EMIS_GUESS ./ div;
    
    EMIS_GUESS = zeros(num_hidden_states,num_bins);
    for bin = 1 : num_bins
       EMIS_GUESS(:,bin) = sum(binseries == bin); 
    end
    EMIS_GUESS = 1/size(binseries,1) * EMIS_GUESS;
    
    [TRANS_EST2, EMIS_EST2, LOG_LIKS] = hmmtrain(binseries', TRANS_GUESS, EMIS_GUESS, 'VERBOSE', false, 'ALGORITHM', 'BaumWelch');
    
    display(sum(sum(abs(TRANS_EST2 - TRANS_GUESS))));
    
    %if sum(sum(abs(TRANS_EST2 - TRANS_GUESS))) > tol
    %    good_estimates = good_estimates + 1;
    param_TRANS(:,:,k) = TRANS_EST2;
    param_EMIS(:,:,k) = EMIS_EST2;
    %end
    
    fprintf('Initial Guess transition matrix:\n');
    disp(TRANS_GUESS);
    fprintf('\nTransition matrix:\n');
    disp(TRANS_EST2);
    fprintf('\nEmission matrix:\n');
    disp(EMIS_EST2);
        
end

close(h);
toc;
