function cvx_optval = sum_smallest( x, varargin )

%SUM_SMALLEST Sum of the smallest k elements of a vector.
%   For a real vector X and an integer k between 1 and length(X) inclusive,
%   y = SUM_SMALLEST(X,k) is the sum of the k smallest elements of X; e.g.,
%       temp = sort( x )
%       y = sum( temp( 1 : k ) )
%   If k=1, then SUM_SMALLEST(X,k) is equivalent to MIN(X); if k=length(X),
%   then SUM_SMALLEST(X,k) is equivalent to SUM(X).
%
%   Both X and k must be real, and k must be a scalar. But k is not, in
%   fact, constrained to be an integer between 1 and length(X); the
%   function is extended continuously and logically to all real k. For
%   example, if k <= 0, then SUM_SMALLEST(X,k)=0. If k > length(X), then
%   SUM_SMALLEST(X,k)=SUM(X). Non-integer values of k interpolate linearly
%   between their integral neighbors.
%
%   For matrices, SUM_SMALLEST(X,k) is a row vector containing the
%   application of SUM_SMALLEST to each column. For N-D arrays, the
%   SUM_SMALLEST operation is applied to the first non-singleton dimension
%   of X.
%
%   SUM_SMALLEST(X,k,DIM) performs the operation along dimension DIM of X.
%
%   Disciplined convex programming information:
%       SUM_SMALLEST(X,...) is concave and nondecreasing in X. Thus, when
%       used in CVX expressions, X must be concave (or affine). k and DIM
%       must both be constant.

narginchk(2,3);
cvx_optval = -sum_largest( -x, varargin{:} );

% Copyright 2005-2016 CVX Research, Inc.
% See the file LICENSE.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.
