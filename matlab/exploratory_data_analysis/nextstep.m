% Now that you have a way of estimating a given (observable doubly stochastic
% Markov chain) model, I would like you to estimate the model on any given day
% of data. Then generate sample paths of the regimes as well as the trades,
% and then re-estimate the model parameters along each sample path. Do this
% for 10,000 sample paths  by generating the same number of trades that you
% observed in the data (the number of regimes changes will of course not
% match). Draw histograms of the re-estimated model parameters and show
% the confidence intervals. For simplicity of exposition, use only three
% regimes for imbalance. You can decide on what regime bands to use by looking
% at data over the year and binning imbalance into thirds.
% 
% TODO:
% - estimate model parameters for given day
% - generate sample paths of the regimes and trades
%     - re-estimate parameters along each path
%     - do this 10,000 times, generate same number of trades as in data
%     - draw histograms of the re-estimated model parameters and show the confidence intervals.


% MO = ExtracMOs(data);
% Extracts Market orders from the event data
%
% column 1: time of event
% column 2: best bid price prior to MO
% column 3: best ask price prior to MO
% column 4: best bid volume prior to MO
% column 5: best ask volume prior to MO
% column 6: average executed price per share
% column 7: consolidated volume of MO
% column 8: buy (-1) sell (+1) indicator
% column 9: highest price paid or lowest price received for that MO
% column 10: exchange
%
% column 11-20: 10 best bid prices prior to MO
% column 21-30: 10 best bid volumes prior to MO
% column 31-40: 10 best ask prices prior to MO
% column 41-50: 10 best ask volumes prior to MO



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% compute rate of arrivals conditional on:
% 1. current imbalance
% 2. current imbalance and previous price change
% 3. current imbalance, previous imbalance. 
% 4. all three.
% Lambda1: same as before.
% Lambda2: dS is a huge indicator for MO arrival, very obviously so.
% Lambda3: bin change => increased activity of MOs
%         - staying in same bin is expected (91.5% of the time)
% Lambda4: pronounced increase in rate when: sells (bin3>bin1), ds=-1
%         prounounced increase in rate when: buys (now in bin2, oddly...), ds=1




% for probabilit matrix:
% play with number of bins, time intervals.
% cross validate the probability matrices.
% naive trading strategy based on this.
% for matrices: probability of price change being at least equal to the
% spread.