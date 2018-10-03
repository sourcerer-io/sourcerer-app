function z = quad_over_lin( x, y, dim )

%QUAD_OVER_LIN Sum of squares over linear.
%   Z=QUAD_OVER_LIN(X,Y), where X is a vector and Y is a scalar, is equal to
%   SUM(ABS(X).^2)./Y if Y is positive, and +Inf otherwise. Y must be real.
%
%   If X is a matrix, QUAD_OVER_LIN(X,Y) is a row vector containing the values
%   of QUAD_OVER_LIN applied to each column. If X is an N-D array, the operation
%   is applied to the first non-singleton dimension of X.
%
%   QUAD_OVER_LIN(X,Y,DIM) takes the sum along the dimension DIM of X.
%   A special value of DIM == 0 is accepted here, which is automatically
%   replaced with DIM == NDIMS(X) + 1. This has the effect of eliminating
%   the sum; thus QUAD_OVER_LIN( X, Y, NDIMS(X) + 1 ) = ABS( X ).^2 ./ Y.
%
%   In all cases, Y must be compatible in the same sense as ./ with the squared
%   sum; that is, Y must be a scalar or the same size as SUM(ABS(X).^2,DIM).
%
%   Disciplined convex programming information:
%       QUAD_OVER_LIN is convex, nonmontonic in X, and nonincreasing in Y.
%       Thus when used with CVX expressions, X must be convex (or affine)
%       and Y must be concave (or affine).

%
% Check arguments
%

narginchk(2,3);
if ~isreal( y ),
    error( 'Second argument must be real.' );
elseif nargin < 3 || isempty( dim ),
    dim = cvx_default_dimension( size( x ) );
elseif ~cvx_check_dimension( dim, true ),
    error( 'Third argument, if supplied, must be a positive integer.' );
elseif dim == 0,
    dim = ndims( x ) + 1;
end

%
% Perform calculation
%

z = sum_square_abs( x, dim );
if length( y ) ~= 1 && ~isequal( size( z ), size( y ) ),
    error( 'Input size mismatch.' );
end
temp = y <= 0;
inf_fix = any( temp );
if inf_fix,
    y( temp ) = 1;
end
z = z ./ y;
if inf_fix,
    z( temp ) = +Inf;
end

% Copyright 2005-2016 CVX Research, Inc.
% See the file LICENSE.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.
