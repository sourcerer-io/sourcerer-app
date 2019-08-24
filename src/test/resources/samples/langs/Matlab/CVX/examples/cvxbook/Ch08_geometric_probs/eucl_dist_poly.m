% Euclidean distance between polyhedra
% Section 8.2.1, Boyd & Vandenberghe "Convex Optimization"
% Joelle Skaf - 10/09/05
%
% Given two polyhedra C = {x | A1*x <= b1} and D = {x | A2*x <= b2}, the
% distance between them is the optimal value of the problem:
%           minimize    || x - y ||_2
%               s.t.    A1*x <= b1
%                       A2*y <= b2

% Input data
randn('state',0);
rand('state',0);

n  = 5;
m1 = 2*n;
m2 = 3*n;
A1 = randn(m1,n);
A2 = randn(m2,n);
b1 = rand(m1,1);
b2 = rand(m2,1) + A2*randn(n,1);

% Solution via CVX
cvx_begin
    variables x(n) y(n)
    minimize (norm(x - y))
    A1*x <= b1;
    A2*y <= b2;
cvx_end

% Displaying results
disp('------------------------------------------------------------------');
disp('The distance between the 2 polyhedra C and D is: ' );
disp(['dist(C,D) = ' num2str(cvx_optval)]);
