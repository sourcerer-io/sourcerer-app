% Weighted analytic center of a set of linear inequalities
% Joëlle Skaf - 04/29/08 
%
% The weighted analytic center of a set of linear inequalities:
%           a_i^Tx <= b_i   i=1,...,m,
% is the solution of the unconstrained minimization problem 
%           minimize    -sum_{i=1}^m w_i*log(b_i-a_i^Tx),
% where w_i>0

% Input data 
randn('state', 0);
rand('state', 0);
n = 10;
m = 50; 
tmp = randn(n,1);
A = randn(m,n); 
b = A*tmp + 2*rand(m,1); 
w = rand(m,1);  

% Analytic center 
cvx_begin
    variable x(n)
    minimize -sum(w.*log(b-A*x))
cvx_end

disp('The weighted analytic center of the set of linear inequalities is: ');
disp(x);
