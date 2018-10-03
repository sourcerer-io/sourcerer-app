% Entropy maximization 
% Joëlle Skaf - 04/24/08
%
% Consider the linear inequality constrained entroy maximization problem 
%           maximize    -sum_{i=1}^n x_i*log(x_i) 
%           subject to  sum(x) = 1 
%                       Fx <= g
% where the variable is x \in \reals^{n} 

% Input data 
randn('state', 0); 
rand('state', 0); 
n = 20; 
m = 10; 
p = 5; 

tmp = rand(n,1); 
A = randn(m,n); 
b = A*tmp; 
F = randn(p,n); 
g = F*tmp + rand(p,1); 

% Entropy maximization 
cvx_begin
    variable x(n) 
    maximize sum(entr(x)) 
    A*x == b 
    F*x <= g
cvx_end

% Results 
display('The optimal solution is:' );
disp(x); 
