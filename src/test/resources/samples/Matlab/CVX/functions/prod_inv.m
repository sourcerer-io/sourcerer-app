function cvx_optval = prod_inv( x, dim, p )

%PROD_INV inverse of the product of a positive vector.
%   For a real vector, matrix, or X, PROD_INV(X) returns 1.0 ./ PROD(X) if
%   the elements of X are all positive, and +Inf otherwise.
%
%   For matrices, PROD_INV(X) is a row vector containing the inverse
%   product of each column of X. For N-D arrays, PROD_INV(X) is an array of
%   inverse products taken along the first non-singleton dimension of X.
%
%   PROD_INV(X,DIM) takes inverse products along the dimension DIM of X.
%
%   PROD_INV(X,DIM,P), where P is a positive real constant, computes
%   PROD_INV(X).^P. This is slightly more efficient than the equivalent
%   POW_POS(PROD_INV(X),P).
%
%   Disciplined convex programming information:
%       PROD_INV(X) is convex and nonincreasing in X; therefore, when used
%       in CVX specifications, its argument must be concave or affine.

narginchk(1,3);
if ~isreal( x ), 
    error( 'First argument must be real.' ); 
elseif nargin < 2,
    dim = cvx_default_dimension( size( x ) );
elseif ~cvx_check_dimension( dim ),
    error( 'Second argument must be a positive integer.' );
end
if nargin < 2,
    p = 1;
elseif ~isnumeric( p ) || ~isreal( p ) || numel( p ) ~=  1 || p <= 0,
    error( 'Third argument must be a positive scalar.' );
end
tt = any( x < 0, dim );
cvx_optval = prod( x, dim ) .^ (-p);
cvx_optval(tt) = +Inf;

% Copyright 2005-2016 CVX Research, Inc. 
% See the file LICENSE.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.
