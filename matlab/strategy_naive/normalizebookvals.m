%% Normalize book values by midprice at open.
function [normed_bookvals, normed_mids] = normalizebookvals(bookvalues,midprices)

    normed_bookvals = bookvalues / midprices(1); 
    normed_mids = midprices / midprices(1);
end