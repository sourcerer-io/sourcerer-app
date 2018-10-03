% Euclidean projection on the nonnegative orthant
% Section 8.1.1, Boyd & Vandenberghe "Convex Optimization"
% Joelle Skaf - 10/07/05
%
% The projection of x0 on the proper cone K = R+^n is given by
%           minimize || x - x0 ||^2
%               s.t.    x >= 0
% It is also given by: P_K(x0)_k = max{x0_k,0}

% Input data
randn('seed',0);
n  = 10;
x0 = randn(n,1);

fprintf(1,'Computing the analytical solution...');

% Analytical solution
pk_x0 = max(x0,0);

fprintf(1,'Done! \n');

% Solution via CVX
fprintf(1,'Computing the solution via a QP...');

cvx_begin quiet
    variable x(n)
    minimize ( norm(x - x0) )
    x >= 0;
cvx_end

fprintf(1,'Done! \n');

% Verification
disp('-----------------------------------------------------------------');
disp('Verifying that the analytical solution and the solution obtained via QP are equal: ');
[pk_x0 x]
disp('They are equal as expected!');
