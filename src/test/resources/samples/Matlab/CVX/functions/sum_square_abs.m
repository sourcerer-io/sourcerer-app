function y = sum_square_abs( x, dim )

%SUM_SQUARE_ABS   Sum of the squares of absolute values.
%   For real arrays, SUM_SQUARE_ABS(X) computes the same result as
%   SUM_SQUARE(X). For complex arrays, SUM_SQUARE(X) first computes the
%   magnitudes of the elements of X, so it compute SUM_SQUARE_ABS(X).
%
%   Similarly, SUM_SQUARE_ABS(X,DIM) implements SUM_SQUARE(ABS(X),DIM).
%
%   Disciplined convex programming information:
%       SUM_SQUARE_ABS(X,...) is convex and nonmonotonic in X. Thus, when
%       used in CVX expressions, X must be affine. DIM must be constant.

narginchk(1,2);
y = conj( x ) .* x;
if nargin == 2,
    y = sum( y, dim );
else
    y = sum( y );
end

% Copyright 2005-2016 CVX Research, Inc.
% See the file LICENSE.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.
