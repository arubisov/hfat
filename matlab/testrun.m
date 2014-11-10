% 0.548
% MO_rounded_times = round(MO(:,1)/dt_avg)*dt_avg;
% 
% dt = 100;
% T1 = 9.5 * 3600000;
% T2 = 16 * 3600000;
% t = [T1 : dt : T2];
% 
% indices_1 = match_indices(t,MO_rounded_times);

% 0.467
% indices_2 = match_mapping(t,MO);


% function [output] = testrun(a)
% 
% if nargin < 1
%     a = 1;
% end
% 
% output = a;

tic;

num_hidden_states = 3;
num_bins = 10;

TRANS_GUESS = rand(num_hidden_states,num_hidden_states);
div = sum(TRANS_GUESS,2);
div = repmat(div,1,num_hidden_states);
TRANS_GUESS = TRANS_GUESS ./ div;

EMIS_GUESS = rand(num_hidden_states,num_bins);
div = sum(EMIS_GUESS,2);
div = repmat(div,1,num_bins);
EMIS_GUESS = EMIS_GUESS ./ div;

% p = rand(1,3);
% p = p / sum(p);
% 
% TRANS_HAT = [0 p; zeros(size(TRANS_GUESS,1),1) TRANS_GUESS];
% 
% EMIS_HAT = [zeros(1,size(EMIS_GUESS,2)); EMIS_GUESS];
% 
% [TRANS_EST2, EMIS_EST2] = hmmtrain(binseries(1:1000)', TRANS_HAT, EMIS_HAT, 'VERBOSE', true, 'ALGORITHM', 'BaumWelch');

[TRANS_EST2, EMIS_EST2] = hmmtrain(binseries', TRANS_GUESS, EMIS_GUESS, 'VERBOSE', true, 'ALGORITHM', 'BaumWelch');

toc;