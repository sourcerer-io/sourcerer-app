function y = sum_log( x, dim )

%SUM_LOG   Sum of logarithms.
%   For vectors, SUM_LOG(X) is the sum of the logarithms of the elements of
%   the vector; i.e., SUM(LOG(X)). If any of the elements of the vector are
%   nonnegative, then the result is -Inf.
%
%   For matrices, SUM_LOG(X) is a row vector containing the application of
%   SUM_LOG to each column. For N-D arrays, the SUM_LOG is applied to the
%   first non-singleton dimension of X.
%
%   SUM_LOG(X,DIM) takes the sum along the dimension DIM of X.
%
%   SUM_LOG(X) could also be written SUM(LOG(X)). However, this version
%   should be more efficient, because it involves only one logarithm.
%
%   Disciplined convex programming information:
%       SUM_LOG(X) is concave and nondecreasing in X. Therefore, when used
%       in CVX expressions, X must be concave. X must be real.

narginchk(1,2);
if ~isreal( x ),
    error( 'Argument must be real.' );
elseif nargin == 2,
    y = sum( log( max( x, 0 ) ), dim );
else
    y = sum( log( max( x, 0 ) ) );
end

% Copyright 2005-2016 CVX Research, Inc.
% See the file LICENSE.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.
