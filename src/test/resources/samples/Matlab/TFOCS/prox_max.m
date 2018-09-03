function op = prox_max( q )

%PROX_MAX    Entry-wise maximum element.
%    OP = PROX_MAX( q ) implements the nonsmooth function
%        OP(X) = q * max( X(:) ).
%    Q is optional; if omitted, Q=1 is assumed. But if Q is supplied,
%    then it must be a positive real scalar.
% Dual: proj_simplex.m (at least if X is a vector)
% See also proj_simplex, prox_linf, prox_linf

if nargin == 0,
	q = 1;
elseif ~isnumeric( q ) || ~isreal( q ) || numel( q ) ~= 1 || q <= 0,
	error( 'Argument must be positive.' );
end
op = @(varargin)prox_lmax_q( q, varargin{:} );

function [ v, x ] = prox_lmax_q( q, x, t )
if nargin < 2,
    error( 'Not enough arguments.' );
end    
% We have two options when input x is a matrix:
%   Does the user want to treat it as x(:), 
%   Or does the user want to treat each column separately?
% Most other functions (e.g. l1, linf) treat it as x(:)
% so that will be the default. However, we leave it
% as a hard-coded option so that the user can change it
% if they want.
% (Note: the dual function, proj_simplex, vectorizes it)
VECTORIZE = true;
% right now, we do not have the non-vectorized version implemented.

tau = max( x(:) );
if nargin == 3,
    s   = sort( nonzeros(x), 'descend' );
%     s   = sort( x, 'descend' ); % 'nonzeros' does a x(:) operation
    cs  = cumsum(s);
    ndx = find( cs - (1:numel(s))' .* [s(2:end);0] >= t * q, 1 );
    if ~isempty( ndx ),
        tau = ( cs(ndx) - t * q ) / ndx;
        x   = x .* ( tau ./ max( x, tau ) );
    else
        x(:) = 0;  % adding Oct 21
        tau = 0;
    end
elseif nargout == 2,
    error( 'This function is not differentiable.' );
end
v = q * tau;

% TFOCS v1.3 by Stephen Becker, Emmanuel Candes, and Michael Grant.
% Copyright 2013 California Institute of Technology and CVX Research.
% See the file LICENSE for full license information.
