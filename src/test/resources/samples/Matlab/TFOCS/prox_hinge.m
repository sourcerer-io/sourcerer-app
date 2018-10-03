function op = prox_hinge( q , r, y)

%PROX_HINGE    Hinge-loss function.
%    OP = PROX_HINGE( q , r, y ) implements the nonsmooth function
%        OP(X) = q * sum( max( r - y.*x, 0 ) ).
%    Q is optional; if omitted, Q=1 is assumed. But if Q is supplied,
%    then it must be a positive real scalar.
%    R is also optional; if omitted, R = 1 is assumed. R may be any real number.
%    Y is also optional; if omitted, Y = 1 is assumed. Y may be any scalar
%       or vector of the same size as X
% Dual: prox_hingeDual.m
%
% See also PROX_HINGEDUAL

if nargin < 3
    y = [];
elseif ~isempty(y) && ( ~isnumeric(y) || ~isreal(y) )
    error( 'Argument 3 must be a real vector');
end
if nargin < 2
	r = 1;
elseif ~isnumeric( r ) || ~isreal( r ) %|| numel( r ) ~= 1
	error( 'Argument 2 must be real.' );
end
if nargin < 1
	q = 1;
elseif ~isnumeric( q ) || ~isreal( q ) || numel( q ) ~= 1 || q <= 0,
	error( 'Argument 1 must be positive.' );
end

if isempty(y) 
    op = tfocs_prox( @(x)hinge(x,r,q), @(x,t)prox_hinge(x,t,r,q) );
else
    ry  = r./y;
    op = tfocs_prox( @(x)hingeY(x,r,q,y), @(x,t)prox_hingeY(x,t,r,q,ry,y) );
end


% -- the actual functions --

function v = hingeY(x,r,q,y)
    if ~isscalar(r), assert( numel(r) == numel(x),'r is wrong size' ); end
    if ~isscalar(y), assert( numel(y) == numel(x),'y is wrong size'); end
    v = q*sum( max( r(:) - y(:).*x(:), 0 ) );
end
function v = hinge(x,r,q)
    if ~isscalar(r), assert( numel(r) == numel(x),'r is wrong size' ); end
    v = q*sum( max( r(:) - x(:), 0 ) );
end


%   PROX_F( Y, t ) = argmin_X  F(X) + 1/(2*t)*|| X - Y ||^2
function x = prox_hinge(x,t,r,q)  
    tq = t * q;
    x = r + (x-r).*( x > r ) + (x + tq - r).*( x + tq < r  );
end
%{
    in the q = r = t = 1 case, the prox is:
prox(x) = {     x, if x > 1
                1, if x <= 1, and x > 0
                x + q, if x <= 0
%}

function x = prox_hingeY(x,t,r,q,ry,y)  
    tq = t * q;
    x = ry + (x-ry).*( y.*x > r ) + (x + tq*y - ry).*( y.*(x + tq*y) < r );
end


end

% Added Feb, 2011; modified Dec, 2011

% TFOCS v1.3 by Stephen Becker, Emmanuel Candes, and Michael Grant.
% Copyright 2013 California Institute of Technology and CVX Research.
% See the file LICENSE for full license information.
