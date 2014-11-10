% data - the data structure 
% dt - time frequency to sample IB in milli seconds
% dT - time to average IB
% dS - look-ahead time for change in mid price.
%
function [ t, IB, dS ] = GetIB( data, dt, dT, dTS)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

    tau = data.Event(:,1);
    
    
    idx = (tau >= 9.5*3600000);
    
    tau = tau(idx)-9.5*3600000;
    sp = data.SellPrice(idx,1);
    bp = data.BuyPrice(idx,1);
    sv = data.SellVolume(idx,1);
    bv = data.BuyVolume(idx,1);
    
    t= [ dT+dt : dt : 6.5*3600000]';
    
    IBt=zeros(length(t),1);
    midS=zeros(length(t),1);
    
    % in case there's not yet a buy value, calculate first step separately.
    i0 = 1;
    while tau(i0) < dT
        i0 = i0 + 1;
    end
        
    IBt(1) = (bv(i0)-sv(i0))/(bv(i0)+sv(i0));
    midS(1) = sp(i0);
    
    for k = 2 : length(t)
        
        % find first index that enters the time interval [t(k) - dT, t(k)]
        while tau(i0) < t(k) - dT
            i0 = i0 + 1;
        end
        i0 = max(1,i0 - 1);
        
        IBt(k) = (bv(i0)-sv(i0))./(bv(i0)+sv(i0));
        midS(k) = 0.5*(sp(i0)+bp(i0));
            
    end
    
    n = floor(dT / dt);
    
    IB = NaN(length(t),1);
    dS = NaN(length(t),1);
    
    for k = n+1 : length(t)-dTS
       IB(k) = mean( IBt(k-n: k) );
       dS(k) = midS(k+dTS)-midS(k);
    end
end

