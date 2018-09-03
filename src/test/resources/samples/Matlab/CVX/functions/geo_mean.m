function y = geo_mean( x, dim, w )

%GEO_MEAN   Geometric mean.
%   Y=GEO_MEAN(X), where X is a vector, computes the geometrix mean of X. If any
%   of the elements of X are negative, then Y=-Inf. Otherwise, it is equivalent
%   to Y=PROD(X).^(1/LENGTH(X)). All elements must be real.
%
%   For matrices, GEO_MEAN(X) is a row vector containing the geometric means of
%   the columns. For N-D arrays, GEO_MEAN(X) is an array of the geometric means
%   taken along the first non-singleton dimension of X.
%
%   GEO_MEAN(X,DIM) takes the geometric mean along the dimension DIM of X.
%
%   GEO_MEAN(X,DIM,W), where W is a vector of nonnegative integers, computes a
%   weighted geometric mean Y = PROD(X.^W)^(1/SUM(W)). This is more efficient
%   than replicating the values of X W times. Note that W must be a vector,
%   even if X is a matrix, and its length must be the same as SIZE(X,DIM).
%
%   Disciplined convex programming information:
%       GEO_MEAN is concave  and nondecreasing; therefore, when used in CVX
%       specifications, its argument must be concave.

%
% Check arguments
%

narginchk(1,3);
if ~isreal( x ), 
    error( 'First argument must be real.' ); 
elseif nargin < 2,
    dim = cvx_default_dimension( size( x ) );
elseif ~cvx_check_dimension( dim ),
    error( 'Second argument must be a positive integer.' );
end
sx = size( x );
nx = sx( dim );

%
% Third argument check
%

if nargin < 3 || isempty( w ),
    w = [];
elseif numel( w ) ~= length( w ) || ~isnumeric( w ) || ~isreal( w ) || any( w < 0 ) || any( w ~= floor( w ) ),
    error( 'Third argument must be a vector of nonnegative integers.' );
elseif length( w ) ~= nx,
    error( 'Third argument must be a vector of length %d.', nx );
else
    w = reshape( w, 1, nx );
end

if nx == 0,
    sx( dim ) = 1;
    y = ones( sx );
else
    if nx == 1,
        y = x;
    elseif isempty( w ) || ~any( diff( w ) ),
        y = exp( sum( log( max( x, realmin ) ), dim ) * ( 1 / nx ) );
    elseif dim == 1,
        y = exp( w * log( max( x, realmin ) ) * ( 1 / sum( w ) ) );
    else
        pvec = [ dim, 1 : dim - 1, dim + 1 : ndims( x ) ];
        y = ipermute( exp( w * log( max( permute( x, pvec ), realmin ) ) * ( 1 / sum( w ) ) ), pvec );
    end
    xmin = min( x, [], dim );
    y( xmin <  0 ) = -Inf;
    y( xmin == 0 ) = 0;
end

% Copyright 2005-2016 CVX Research, Inc. 
% See the file LICENSE.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.
