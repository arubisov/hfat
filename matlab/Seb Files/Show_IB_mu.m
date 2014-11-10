midrho = 0.5 * (rho(2:end)+rho(1:end-1));
Lambda_s = sum(mu_s,2);
Lambda_b = sum(mu_b,2);

for k = 1 : size(mu_b,1)
    
    lambda_b(k,:) = mu_b(k,:)/Lambda_b(k);
    lambda_s(k,:) = mu_s(k,:)/Lambda_s(k);
    
    f = figure(1);
    clf(f);
    plot(midrho, lambda_b(k,:), '-o', midrho, lambda_s(k,:), '-s');
    ylim([0 0.5]);
    getframe();
    pause(1);
    
end