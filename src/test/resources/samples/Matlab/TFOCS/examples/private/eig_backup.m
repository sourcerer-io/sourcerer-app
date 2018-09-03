function [V,D] = eig_backup( X )
% [V,D] = eig_backup(X)
%   computes the eigenvalue decomposition of a symmetric matri
%   using the SVD. This is designed for cases when the main eig()
%   routine doesn't work due to the bug described at 
%       http://ask.cvxr.com/t/eig-did-not-converge-in-prox-trace/996/4
%
% This uses the SVD, so a bit slower sometimes...
% July 13 2015

[V,D,W] = svd(X);


d = diag(D).' .* sign(real(dot(V,W,1)));
% and sort it to conform to Matlab's order...
[d,ind]     = sort(d);
D           = diag(d);
V           = V(:,ind);

% Another option, but typically slow...
%   (calls generalized eigenvalue decomp.)/
% [V,D]   = eig(X,eye(size(X)));