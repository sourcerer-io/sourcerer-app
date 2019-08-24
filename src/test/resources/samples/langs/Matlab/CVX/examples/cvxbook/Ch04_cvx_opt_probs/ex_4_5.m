% Exercise 4.5: Show the equivalence of 3 convex problem formations
% From Boyd & Vandenberghe, "Convex Optimization"
% Joëlle Skaf - 08/17/05
%
% Shows the equivalence of the following 3 problems:
% 1) Robust least-squares problem
%           minimize    sum_{i=1}^{m} phi(a_i'*x - bi)
%    where phi(u) = u^2             for |u| <= M
%                   M(2|u| - M)     for |u| >  M
% 2) Least-squares with variable weights
%           minimize    sum_{i=1}^{m} (a_i'*x - bi)^2/(w_i+1) + M^2*1'*w
%               s.t.    w >= 0
% 3) Quadratic program
%           minimize    sum_{i=1}^{m} (u_i^2 + 2*M*v_i)
%               s.t.    -u - v <= Ax - b <= u + v
%                       0 <= u <= M*1
%                       v >= 0

% Generate input data
randn('state',0);
m = 16; n = 8;
A = randn(m,n);
b = randn(m,1);
M = 2;

% (a) robust least-squares problem
disp('Computing the solution of the robust least-squares problem...');
cvx_begin
    variable x1(n)
    minimize( sum(huber(A*x1-b,M)) )
cvx_end

% (b)least-squares problem with variable weights
disp('Computing the solution of the least-squares problem with variable weights...');
cvx_begin
    variable x2(n)
    variable w(m)
    minimize( sum(quad_over_lin(diag(A*x2-b),w'+1)) + M^2*ones(1,m)*w)
    w >= 0;
cvx_end

% (c) quadratic program
disp('Computing the solution of the quadratic program...');
cvx_begin
    variable x3(n)
    variable u(m)
    variable v(m)
    minimize( sum(square(u) +  2*M*v) )
    A*x3 - b <= u + v;
    A*x3 - b >= -u - v;
    u >= 0;
    u <= M;
    v >= 0;
cvx_end

% Display results
disp('------------------------------------------------------------------------');
disp('The optimal solutions for problem formulations 1, 2 and 3 are given');
disp('respectively as follows (per column): ');
[x1 x2 x3]
