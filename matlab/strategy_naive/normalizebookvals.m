%% Normalize book values by midprice at open.
function normed_bookvals = normalizebookvals(data, bookvalues)

    T1 = 9.5 * 3600000;
    T1_idx = find(data.Event(:,1) >= T1, 1, 'first');
    
    mid_price = (data.BuyPrice(T1_idx,1) + data.SellPrice(T1_idx,1))/20000;
    
    normed_bookvals = bookvalues / mid_price; 
end