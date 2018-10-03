function op = prox_l2( q )

%PROX_L2    L2 norm.
%    OP = PROX_L2( q ) implements the nonsmooth function
%        OP(X) = q * norm(X,'fro').
%    Q is optional; if omitted, Q=1 is assumed. But if Q is supplied,
%    then it must be a positive real scalar.
%    If Q is a vector or matrix of the same size and dimensions as X,
%       then this uses an experimental code to compute the proximity operator
%       of OP(x) = norm( q.*X, 'fro' )
%    In the limit q --> 0, this function acts like prox_0 (aka proj_Rn)
% Dual: proj_l2.m
% For the proximity operator of the l2 squared norm (that is, norm(X,'fro')^2)
%   use smooth_quad.m (which can be used in either a smooth gradient-based fashion
%   but also supports proximity usage). Note smooth_quad() is self-dual.
% See also proj_l2, prox_0, proj_Rn

% Feb '11, allowing for q to be a vector
%       This is complicated, so not for certain
%       A safer method is to use a linear operator to scale the variables

if nargin == 0,
	q = 1;
% elseif ~isnumeric( q ) || ~isreal( q ) || numel( q ) ~= 1 || q <= 0,
elseif ~isnumeric( q ) || ~isreal( q ) %||  any( q < 0 ) || all(q==0)
	error( 'Argument must be positive.' );
end
if isscalar(q)
    if any( q <= 0 )
        error('Scaling argument must be positive, real scalar. If q=0, use prox_0 instead');
    end
    op = @(varargin)prox_l2_q( q, varargin{:} );
else
    if all(q==0), error('Argument must be nonzero'); end
    warning('TFOCS:experimental','Using experimental feature of TFOCS');
    op = @(varargin)prox_l2_vector( q, varargin{:} );
end

function [ v, x ] = prox_l2_q( q, x, t )
if nargin < 2,
	error( 'Not enough arguments.' );
end
v = sqrt( tfocs_normsq( x ) ); 
if nargin == 3,
	s = 1 - 1 ./ max( v / ( t * q ), 1 ); 
   
	x = x * s;
	v = v * s; % version A
elseif nargout == 2,
	error( 'This function is not differentiable.' );
end
v = q * v; % version A


% --------- experimental code -----------------------
function [ v, x ] = prox_l2_vector( q, x, t )
if nargin < 2,
	error( 'Not enough arguments.' );
end
v = sqrt( tfocs_normsq( q.*x ) ); % version B
if nargin == 3,
%{
   we need to solve for a scalar variable s = ||q.*x|| 
      (where x is the unknown solution)
    
   we have a fixed point equation:
        s = f(s) := norm( q.*x_k ) where x_k = x_0/( 1 + t*q/s )
   
   to solve this, we'll use Matlab's "fzero" to find the zero
    of the function F(s) = f(s) - s
    
   Clearly, we need s >= 0, since it is ||q.*x||
    
   If q is a scalar, we can solve explicitly: s = q*(norm(x0) - t)
    
%}
    
    xk = @(s) x./( 1 + t*(q.^2)/s );
    f = @(s) norm( q.*xk(s) );
%     F = @(s) f(s) - s;
    tq2 = t*(q.^2);
    F = @(s) norm( (q.*x)./( 1 + tq2/s ) ) - s;
    [s,sVal] = fzero( F, 1);
    if abs( sVal ) > 1e-4
        error('cannot find a zero'); 
    end
    if s <= 0
        x = 0*x;
    else
        x = xk(s);
    end
    v = sqrt( tfocs_normsq( q.*x ) ); % version B
elseif nargout == 2,
	error( 'This function is not differentiable.' );
end

% TFOCS v1.3 by Stephen Becker, Emmanuel Candes, and Michael Grant.
% Copyright 2013 California Institute of Technology and CVX Research.
% See the file LICENSE for full license information.
