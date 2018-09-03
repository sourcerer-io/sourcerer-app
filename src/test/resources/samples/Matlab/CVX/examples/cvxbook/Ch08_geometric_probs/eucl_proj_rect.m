% Euclidean projection on a rectangle
% Section 8.1.1, Boyd & Vandenberghe "Convex Optimization"
% Joelle Skaf - 10/07/05
%
% The projection of x0 on a rectangle C = {x | l <= x <= u} is given by
%           minimize || x - x0 ||^2
%               s.t.    l <= x <= u
% It is also given by P_C(x0)_k = l_k       if  x0_k <= l_k
%                                 x0_k      if  l_k <= x0_k <= u_k
%                                 u_k       if  x0_k >= u_k

% Input data: generate vectors l and u such that l < 0 < u
n  = 10;
l  = -rand(n,1);
u  = rand(n,1);
x0 = randn(n,1);

% Analytical solution
fprintf(1,'Computing the analytical solution ...');
pc_x0 = x0;
pc_x0(find(x0<=l)) = l(find(x0<=l));
pc_x0(find(x0>=u)) = u(find(x0>=u));
fprintf(1,'Done! \n');

% Solution via QP
fprintf(1,'Computing the optimal solution by solving a QP ...');

cvx_begin quiet
    variable x(n)
    minimize ( norm(x-x0) )
    x <= u;
    x >= l;
cvx_end

fprintf(1,'Done! \n');

% Verification
disp('-----------------------------------------------------------------');
disp('Verifying that the analytical solution and the solution obtained via QP are equal: ');
[pc_x0 x]
