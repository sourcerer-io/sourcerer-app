function cvx_optval = sum_largest( x, k, dim )

%SUM_LARGEST Sum of the largest k values of a vector.
%   For a real vector X and an integer k between 1 and length(X) inclusive,
%   y = SUM_LARGEST(X,k) is the sum of the k largest elements of X; e.g.,
%       temp = sort( x )
%       y = sum( temp( 1 : k ) )
%   If k=1, then SUM_LARGEST(X,k) is equivalent to MAX(X); if k=length(X),
%   then SUM_LARGEST(X,k) is equivalent to SUM(X).
%
%   Both X and k must be real, and k must be a scalar. But k is not, in
%   fact, constrained to be an integer between 1 and length(X); the
%   function is extended continuously and logically to all real k. For
%   example, if k <= 0, then SUM_LARGEST(X,k)=0. If k > length(X), then
%   SUM_LARGEST(X,k)=SUM(X). Non-integer values of k interpolate linearly
%   between their integral neighbors.
%
%   For matrices, SUM_LARGEST(X,k) is a row vector containing the
%   application of SUM_LARGEST to each column. For N-D arrays, the
%   SUM_LARGEST operation is applied to the first non-singleton dimension
%   of X.
%
%   SUM_LARGEST(X,k,DIM) performs the operation along dimension DIM of X.
%
%   Disciplined convex programming information:
%       SUM_LARGEST(X,...) is convex and nondecreasing in X. Thus, when
%       used in CVX expressions, X must be convex (or affine). k and DIM
%       must both be constant.

%
% Check arguments
%

narginchk(2,3);
if ~isreal( x ),
    error( 'First argument must be real.' );
elseif ~isnumeric( k ) || ~isreal( k ) || length( k ) ~= 1,
    error( 'Second argument must be a real scalar.' );
elseif nargin < 3 || isempty( dim ),
    dim = cvx_default_dimension( size( x ) );
elseif ~cvx_check_dimension( dim, false ),
    error( 'Third argument, if supplied, must be a positive integer.' );
end

%
% Determine output size
%

sx = size( x );
nd = max( dim, length( sx ) );
sx = [ sx, ones( 1, dim - nd ) ];
sy = sx;
sy( dim ) = 1;

%
% Compute results
%

if k <= 0,

    cvx_optval = zeros( sy );

elseif k <= 1,

    cvx_optval = k * max( x, [], dim );

elseif k >= sx( dim ),

    cvx_optval = sum( x, dim );

else

    ck = ceil( k );
    x = sort( x, dim );
    ndxs = cell( 1, nd );
    [ ndxs{:} ] = deal( ':' );
    ndxs{ dim } = size( x, dim ) - ( 0 : ck - 1 );
    x = x( ndxs{ : } );
    if k ~= ck,
        ndxs{ dim } = ck;
        x( ndxs{ : } ) = ( k - floor( k ) ) * x( ndxs{ : } );
    end
    cvx_optval = sum( x, dim );

end

% Copyright 2005-2016 CVX Research, Inc.
% See the file LICENSE.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.
