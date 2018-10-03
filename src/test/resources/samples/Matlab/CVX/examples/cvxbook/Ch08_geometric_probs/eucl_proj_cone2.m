% Euclidean projection on the semidefinite cone
% Sec. 8.1.1, Boyd & Vandenberghe "Convex Optimization"
% Joelle Skaf - 10/07/05
%
% The projection of X0 on the proper cone K = S+^n is given by
%           minimize    ||X - X0||_F
%               s.t.    X >=0
% where X is a nxn matrix and ||.||_F is the Frobenius norm
% It is also given by: P_K(X0)_k = sum_{i=1}^{n}max{0,lam_i}v_i*v_i'
% s.t. X0= sum_{i=1}^{n}lam_i*v_i*v_i'is the eigenvalue decomposition of X0

% Input data
randn('seed',0);
n  = 10;
X0 = randn(n);
X0 = 0.5 * (X0 + X0');
[V,lam] = eig(X0);

fprintf(1,'Computing the analytical solution...');
% Analytical solution
pk_X0 = V*max(lam,0)*V';
fprintf(1,'Done! \n');

% Solution via CVX
fprintf(1,'Computing the optimal solution by solving an SDP...');

cvx_begin sdp quiet
    variable X(n,n) symmetric
    minimize ( norm(X-X0,'fro') )
    X >= 0;
cvx_end

fprintf(1,'Done! \n');

% Verification
disp('-----------------------------------------------------------------');
disp('Verifying that the analytical solution and the solution obtained ');
disp('via CVX are equal by computing ||X_star - P_K(X0)||_F: ');
norm(X-pk_X0,'fro')
disp('Hence X_star and P_K(X0) are equal to working precision.');




