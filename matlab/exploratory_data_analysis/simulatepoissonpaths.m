%%% Simulate the doubly stochastic Poisson process.

num_paths = 10000;
num_arrivals = 3828;
rand_seed = 1;

[param_G, param_lambda] = DoublyStochasticPoissonSim(G, lambda, num_arrivals, num_paths, rand_seed);

save('simulation20140718');