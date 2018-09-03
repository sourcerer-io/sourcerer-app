% Figure 6.9: An optimal tradeoff curve
% Section 6.3.3
% Boyd & Vandenberghe "Convex Optimization"
% Original by Lieven Vandenberghe
% Adapted for CVX Joelle Skaf - 09/29/05
% (a figure is generated)
%
% Plots the optimal trade-off curve between ||Dx||_2 and ||x-x_cor||_2 by
% solving the following problem for different values of delta:
%           minimize    ||x - x_cor||^2 + delta*||Dx||^2
% where x_cor is the a problem parameter, ||Dx|| is a measure of smoothness

%Input data
randn('state',0);
n = 4000;  t = (0:n-1)';
exact = 0.5*sin((2*pi/n)*t).*sin(0.01*t);
corrupt = exact + 0.05*randn(size(exact));

e = ones(n,1);
D = spdiags([-e e], -1:0, n, n);

% tradeoff curve
nopts = 50;
lambdas = logspace(-10,10,nopts);
obj1 = zeros(1,nopts);
obj2 = zeros(1,nopts);

fprintf(1,'Generating the optimal trade-off curve for different values of delta...\n');
for i=1:nopts
    disp(['* delta = ' num2str(lambdas(i))]);
    cvx_begin quiet
        variable x(n)
        minimize ( norm(x - corrupt) + lambdas(i)*norm(D*x) )
    cvx_end
    obj1(i) = norm(x - corrupt);
    obj2(i) = norm(D*x);
end
fprintf(1,'Done! \n');

% Plots
plot(obj1, obj2)
xlabel('||x - x_{cor}||_2');
ylabel('||Dx||_2');
title('Optimal trade-off curve');
% print -deps smoothrec_tradeoff.eps
