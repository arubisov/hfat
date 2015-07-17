function [array_out] = removeillegaltimes(array_in)

    T1 = 9.5 * 3600000;
    T2 = 16 * 3600000;
    
    for from = 1 : size(array_in,1)
        if array_in(from,1) < T1
            continue
        else
            break
        end
    end
    
    for to = size(array_in,1) : -1 : 1
        if array_in(to,1) > T2
            continue
        else
            break
        end
    end
    
    array_out = array_in(from:to,:);
    
end