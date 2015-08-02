function MO = ExtractMOs(data)
% Extracts Market orders from the event data
%
% returns are in MO
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

% column 11-20: 10 best bid prices prior to MO
% column 21-30: 10 best bid volumes prior to MO
% column 31-40: 10 best ask prices prior to MO
% column 41-50: 10 best ask volumes prior to MO
    arg1=data.Event;
    arg2=data.SellVolume;
    arg3=data.SellPrice;
    arg4=data.BuyVolume;
    arg5=data.BuyPrice;        

    MO = market_order_extraction(arg1,arg2,arg3,arg4,arg5);

    clear('arg1','arg2','arg3','arg4','arg5');

end