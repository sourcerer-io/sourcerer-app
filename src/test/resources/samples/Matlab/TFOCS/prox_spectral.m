function op = prox_spectral( q, SYM_FLAG )
%PROX_SPECTRAL    Spectral norm, i.e. max singular value.
%    OP = PROX_SPECTRAL( q ) implements the nonsmooth function
%        OP(X) = q * max(svd(X)).
%    Q is optional; if omitted, Q=1 is assumed. But if Q is supplied, 
%    it must be a positive real scalar.
%
%    OP = PROX_SPECTRAL( q , 'sym' ) or OP = PROX_SPECTRAL( q, 'eig' )
%    will instruct the code that the matrix is Hermitian and 
%    therefore the relations between singular- and eigen-values
%    are well known, and the code will use the more efficient
%    eigenvalue decomposition (instead of the SVD).
%
% This implementation uses a naive approach that does not exploit any
% a priori knowledge that X is low rank or sparse. Future
% implementations of TFOCS will be able to handle low-rank matrices 
% more effectively.
%
% Dual:  proj_nuclear.m
% See also proj_nuclear, prox_linf, prox_maxEig

% Note: it would be possible to use eigs for sparse matrices,
% but that requires a little bit more work than it did for proj_spectral.


if nargin == 0,
	q = 1;
elseif ~isnumeric( q ) || ~isreal( q ) || numel( q ) ~= 1 || q <= 0,
	error( 'Argument must be positive.' );
end
if nargin >= 2 && ( ...
        ~isempty(strfind(lower(SYM_FLAG),'eig')) || ...
        ~isempty(strfind(lower(SYM_FLAG),'sym')) )
    op = @(varargin)prox_spectral_eig_q( q, varargin{:} );
else
    op = @(varargin)prox_spectral_impl( q, varargin{:} );
end

function [ v, X ] = prox_spectral_impl( q, X, t )
if nargin < 2,
    error( 'Not enough arguments.' );
end

if nargin == 3 && t > 0,
    [U,S,V] = svd( full(X), 'econ' );
    s = diag(S);
    tau = s(1);

    cs  = cumsum(s);
    ndx = find( cs - (1:numel(s))' .* [s(2:end);0] >= t * q, 1 );
    if ~isempty( ndx ),
        tau = ( cs(ndx) - t * q ) / ndx;
        s   = s .* ( tau ./ max( abs(s), tau ) );
    end
    X = U*diag(s)*V';
else
    if nargout == 2
        error( 'This function is not differentiable.' );
    end
    if issparse(X)
        tau = normest(X);
    else
        tau = norm(X);
    end
end
v = q * tau; 

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
    op          = prox_linf(q);
    s           = diag(S);
    [dummy,s]   = op(s,t);
%     tau         = max(s); % for SVD, s >= 0 so we can do max. Not so for eig.
    tau         = norm(s,Inf);
    X = V*diag(s)*V';
else
    if nargout == 2
        error( 'This function is not differentiable.' );
    end
    if issparse(X)
        tau = normest(X);
    else
        tau = norm(X);
    end
end
v = q * tau; 

% TFOCS v1.3 by Stephen Becker, Emmanuel Candes, and Michael Grant.
% Copyright 2013 California Institute of Technology and CVX Research.
% See the file LICENSE for full license information.
