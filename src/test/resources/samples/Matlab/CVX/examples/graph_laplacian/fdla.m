function [ w, cvx_optval ] = fdla( A )

% Computes the fastest distributed linear averaging (FDLA) edge weights
%
% [W,S] = FDLA(A) gives a vector of the fastest distributed linear averaging
% edge weights for a graph described by the incidence matrix A (n x m).
% Here n is the number of nodes and m is the number of edges in the graph;
% each column of A has exactly one +1 and one -1.
%
% The FDLA edge weights are given by the SDP:
%
%   minimize    s
%   subject to  -s*I <= I - L - (1/n)11' <= s*I
%
% where the variables are edge weights w in R^m and s in R.
% Here L is the weighted Laplacian defined by L = A*diag(w)*A'.
% The optimal value is s, and is returned in the second output.
%
% For more details see the references:
% "Fast linear iterations for distributed averaging" by L. Xiao and S. Boyd
% "Convex Optimization of Graph Laplacian Eigenvalues" by S. Boyd
%
% Written for CVX by Almir Mutapcic 08/29/06

[n,m] = size(A);
I = eye(n,n);
J = I - (1/n) * ones(n,n);
cvx_begin sdp
    variable w(m,1)   % edge weights
    variable s        % epigraph variable
    variable L(n,n) symmetric
    minimize( s )
    subject to
        L == A * diag(w) * A';
        -s * I <= J - L <= s * I;
cvx_end
