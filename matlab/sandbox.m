    day_size = (T2-T1)/dt_Z;
    num_days = size(dS,1) / day_size;
    
  
    from_idx = 0;
    to_idx = 0;
    
    for day = 1 : num_days
        from_idx = to_idx + 1;
        to_idx = day * day_size;
        if idx(to_idx) ~= 1
            fprintf('irregular day on %d',day);
        end
        
    end