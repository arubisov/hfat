%% Compute a probability matrix for price change, given 2-D CTMC of joint distribution (I, dS)
% data              data to run against
% dt_imbalance_avg  time increment over which to average imbalances
% num_bins          number of bins to cast the imbalances into
% dt_prive_chg      time increment over which to measure price change

function [P_bid, P_ask, binseries, bidchgseries, G_binbid, N_bid] = computeprobabilitypricechange(data, dt_imbalance_avg, num_bins, dt_price_chg, ib_avg_method)

    if exist('data','var') == 0
        load('./data/ORCL_20130515.mat');
       % load('./data/FARO_20131016.mat');
    end

    if exist('dt_imbalance_avg','var') == 0
        dt_imbalance_avg = 1000;
    end
    
    if exist('num_bins','var') == 0
        num_bins = 5;
    end
    
    if exist('dt_price_chg','var') == 0
        dt_price_chg = 500;
    end
    
    [t, binseries, bidchgseries, askchgseries, G_binbid, G_binask]= getbinpricetimeseries(data, dt_imbalance_avg, num_bins, dt_price_chg, ib_avg_method);
    
    P_bid = calculateP(G_binbid, dt_imbalance_avg, num_bins);
    P_ask = calculateP(G_binask, dt_imbalance_avg, num_bins);
    
    N_bid = calculateN(binseries, bidchgseries, num_bins);
    N_ask = calculateN(binseries, askchgseries, num_bins);
    
    
function P = calculateP(G, dt_imbalance_avg, num_bins)
    
    % one-step probability matrix:
    P_onestep = expm(G*dt_imbalance_avg/1000);
    
    % entries of P_onestep are P[ I_n=i, dS_n=j | I_n-1=k, dS_n-1=m ]
    % rewrite that as B == I_n-1=k, dS_n-1=m, so that:
    % entries of P_onestep are  P[ I_n=i, dS_n=j | B ]
    % by Bayes' Rule, this is = P[ dS_n=j | B, I_n=i ] * P[ I_n = i | B ]
    
    % since we want the probabilities of price change, we can rewrite as:
    % P[ dS_n = j | B, I_n = i ] = P[ I_n=i, dS_n=j | B ] \ P[ I_n=1 | B ]
    
    % what are the sizes of these matrices? how do we compute them?
    
    % P(I_n=i | B) = sum P(I_n=1, dS_n=j | B). ie sum across the possible
    % price changes. 
    
    % ok so remember: in G and in P_onestep, element (ij) is transitioning
    % FROM i TO j. This is what we call a right-stochastic matrix.
    
    % (curr price change, previous B, curr bin)
    P = zeros(3,num_bins*3,num_bins);
    
    % variables will be named in terms of what we're solving.
    % we want probability = numerator / denominator

    % also, to go from pair (rho, dS) to an entry in the
    % matrix, the conversion is rho + num_bins*(dS+1)
    
    
    for rho_n = 1 : num_bins
        for B = 1 : num_bins*3
            denom = 0;
            for j = 0 : 2  % to sum over possible price changes
                denom = denom + P_onestep(B , rho_n + num_bins*j);
            end
        
            for dS_n = -1 : 1
                numer = P_onestep(B , rho_n + num_bins * (dS_n+1));
                
                prob = numer / denom;
                if numer > 0 || denom > 0
                    P(dS_n+2, B, rho_n) = prob;
                else
                    P(dS_n+2, B, rho_n) = 0;
                end
            end
        end
    end
    
function N = calculateN(binseries, chgseries, num_bins)

    % convert to 1D series by encoding.
    series = [binseries(1:end-1) sign(chgseries)];
    series(:,2) = series(:,2) + 1;
    series = series * [1;num_bins];

    N = zeros(3,num_bins*3,num_bins);
    
    for rho_n = 1 : num_bins
        for B = 1 : num_bins*3
            N(:, B, rho_n) = sum((series==B) .* (binseries(2:end) == rho_n));
        end
    end