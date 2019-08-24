function [w,rho] = best_const(A)
% Computes the constant edge weight that yields fastest averaging.
%
% [W,RHO] = BEST_CONST(A) gives a vector of the best constant edge weights
% for a graph described by the incidence matrix A (NxM). N is the number of
% nodes, and M is the number of edges. Each column of A has exactly one +1
% and one -1. 
%
% The best constant edge weight is the inverse of the average of
% the second smallest and largest eigenvalues of the unweighted Laplacian:
%    W = 2/( lambda_2(A*A') + lambda_n(A*A') )
% RHO is computed from the weights W as follows:
%    RHO = max(abs(eig( eye(n,n) - (1/n)*ones(n,n) - A*W*A' ))).
%
% For more details, see the references:
% "Fast linear iterations for distributed averaging" by L. Xiao and S. Boyd
% "Fastest mixing Markov chain on a graph" by S. Boyd, P. Diaconis, and L. Xiao
% "Convex Optimization of Graph Laplacian Eigenvalues" by S. Boyd
%
% Almir Mutapcic 08/29/06
[n,m] = size(A);

% max degrees of the nodes
Lunw = A*A';                % unweighted Laplacian matrix
eigvals = sort(eig(Lunw));

% max degree weigth allocation
alpha = 2/(eigvals(2) + eigvals(n));
w = alpha*ones(m,1);

% compute the norm
if nargout > 1,
    rho = norm( eye(n) - A*diag(w)*A' - (1/n)*ones(n) );
end

