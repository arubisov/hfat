num_paths = 1;
rand_seed = 1;

[ h ] = finDiff_h( );
[ deltastar ] = optimal_delta( h );
[ hist_Q, hist_Z, hist_S, hist_d, hist_Mb, hist_Ms, hist_Filled ] = ...
                            sim_inventory(num_paths, rand_seed, deltastar);
plotsim(  hist_Q, hist_Z, hist_S, hist_d, hist_Mb, hist_Ms, hist_Filled );





%%%% Simulate Inventory only!
% num_paths = 10000;
% rand_seed = 1;
% 
% %[ h ] = finDiff_h( );
% %[ deltastar ] = optimal_delta( h );
% tic;
% [ hist_Q ] = sim_inventory_only(num_paths, rand_seed, deltastar);
% toc;
% %save('simulatedQ');