for row=1:size(G,1)
    for col=1:size(G,2)
        fprintf('%6.3f & ',round(G(row,col)*1000)/1000);
    end
    fprintf('\b\b\\\\ \n');
end