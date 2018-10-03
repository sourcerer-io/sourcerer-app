% Section 8.5.3: Analytic center of a set of linear inequalities
% Boyd & Vandenberghe "Convex Optimization" 
% Joëlle Skaf - 04/29/08 
%
% The analytic center of a set of linear inequalities and equalities:
%           a_i^Tx <= b_i   i=1,...,m,
%           Fx = g,
% is the solution of the unconstrained minimization problem 
%           minimize    -sum_{i=1}^m log(b_i-a_i^Tx).

% Input data 
randn('state', 0);
rand('state', 0);
n = 10;
m = 50; 
p = 5;
tmp = randn(n,1);
A = randn(m,n); 
b = A*tmp + 10*rand(m,1); 
F = randn(p,n); 
g = F*tmp; 

% Analytic center 
cvx_begin
    variable x(n)
    minimize -sum(log(b-A*x))
    F*x == g
cvx_end

disp(['The analytic center of the set of linear inequalities and ' ... 
      'equalities is: ']);
disp(x);
