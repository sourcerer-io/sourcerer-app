function [w,rho] = mh(A)
% Computes the Metropolis-Hastings heuristic edge weights
%
% [W,RHO] = MH(A) gives a vector of the Metropolis-Hastings edge weights
% for a graphb described by the incidence matrix A (NxM). N is the number
% of nodes, and M is the number of edges. Each column of A has exactly one
% +1 and one -1. RHO is computed from the weights W as follows:
%    RHO = max(abs(eig( eye(n,n) - (1/n)*ones(n,n) - A*W*A' ))).
%
% The M.-H. weight on an edge is one over the maximum of the degrees of the
% adjacent nodes.
%
% For more details, see the references:
% "Fast linear iterations for distributed averaging" by L. Xiao and S. Boyd
% "Fastest mixing Markov chain on a graph" by S. Boyd, P. Diaconis, and L. Xiao
% "Convex Optimization of Graph Laplacian Eigenvalues" by S. Boyd
%
% Almir Mutapcic 08/29/06

% degrees of the nodes
[n,m] = size(A);
Lunw = A*A';          % unweighted Laplacian matrix
degs = diag(Lunw);

% Metropolis-Hastings weights
mh_degs = abs(A)'*diag(degs);
w = 1./max(mh_degs,[],2);

% compute the norm
if nargout > 1,
    rho = norm( eye(n) - A*diag(w)*A' - (1/n)*ones(n) );
end

