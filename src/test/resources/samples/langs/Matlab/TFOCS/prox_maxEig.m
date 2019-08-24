function op = prox_maxEig( q )
%PROX_MAXEIG    Maximum eigenvalue of a real symmetric matrix
%    OP = PROX_MAXEIG( q ) implements the nonsmooth function
%        OP(X) = q * max(eig(X)).
%    Q is optional; if omitted, Q=1 is assumed. But if Q is supplied, 
%    it must be a real scalar.
%
% Note: if X is positive semi-definite, then max(eig(X)) == norm(eig(X),Inf)
%   and hence prox_maxEig(q) is equivalent to prox_spectral(q,'eig')
%
% This implementation uses a naive approach that does not exploit any
% a priori knowledge that X is low rank or sparse. Future
% implementations of TFOCS will be able to handle low-rank matrices 
% more effectively.
%
% Dual:  proj_psdUTrace.m
% See also proj_psdUTrace, prox_max, prox_spectral, proj_nuclear

% Note: it would be possible to use eigs for sparse matrices,
% but that requires a little bit more work than it did for proj_spectral.

if nargin == 0,
	q = 1;
elseif ~isnumeric( q ) || ~isreal( q ) || numel( q ) ~= 1 %|| q <= 0,
	error( 'Argument must be a real scalar.' );
end
op = @(varargin)prox_spectral_eig_q( q, varargin{:} );

function [ v, X ] = prox_spectral_eig_q( q, X, t )
% Assumes X is square and symmetric
% Therefore, all singular values are just absolute values
%   of the eigenvalues.
if nargin < 2,
    error( 'Not enough arguments.' );
end
if size(X,1) ~= size(X,2)
    error('prox_spectral: variable must be a square matrix');
end
if norm( X - X', 'fro' ) > 1e-10*norm(X,'fro')
    error('Input must be Hermitian');
end
X = (X+X')/2; % Matlab will make it exactly symmetric

if nargin == 3 && t > 0,
    [V,S]       = safe_eig(full(X));
%     op          = prox_linf(q); % for prox_spectral
    op          = prox_max(q);
    s           = diag(S);
    [dummy,s]   = op(s,t);
    tau         = max(s);
    X = V*diag(s)*V';
else
    if nargout == 2
        error( 'This function is not differentiable.' );
    end
    tau = max(eig(X));
end
v = q * tau; 

% TFOCS v1.3 by Stephen Becker, Emmanuel Candes, and Michael Grant.
% Copyright 2013 California Institute of Technology and CVX Research.
% See the file LICENSE for full license information.
