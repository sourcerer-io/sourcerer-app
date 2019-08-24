% Euclidean projection on a hyperplane
% Section 8.1.1, Boyd & Vandenberghe "Convex Optimization"
% Joelle Skaf - 10/04/05
%
% The projection of x0 on a hyperplane C = {x | a'*x = b} is given by
%           minimize || x - x0 ||^2
%               s.t.    a'*x = b
% It is also given by P_C(x0) = x0 + (b - a'*x0)*a/||a||^2

% Input data
randn('seed',0);
n  = 10;
a  = randn(n,1);
b  = randn(1);
x0 = randn(n,1);

% Analytical solution
fprintf(1,'Computing the analytical solution ...');
pc_x0 = x0 + (b - a'*x0)*a/norm(a)^2;
fprintf(1,'Done! \n');

% Solution via QP
fprintf(1,'Computing the optimal solution by solving a QP ...');

cvx_begin quiet
    variable x(n)
    minimize ( square_pos(norm(x - x0)) )
    a'*x == b;
cvx_end

fprintf(1,'Done! \n');

% Verification
disp('--------------------------------------------------------------------------------');
disp('Verifying that p_C(x0) and x_star belong to the hyperplane C: ');
disp(['a^T*p_C(x0) - b = ' num2str(a'*pc_x0 - b)]);
disp(['a^T*x_star - b  = ' num2str(a'*x - b)]);
disp('Computing the distance between x0 and the hyperplane in each case');
disp(['||x0 - p_C(x0)|| = ' num2str(norm(x0 - pc_x0))]);
disp(['||x0 - x_star || = ' num2str(norm(x0 - x))]);
disp('Verifying that the analytical solution and the solution obtained via QP are equal: ');
[pc_x0 x]
