function cvx_optval = log_prod( X, dim )

%LOG_PROD   Logarithm of the product of a vector.
%   For a vector X, LOG_PROD(X) returns
%       LOG(PROD(X))
%   if all of the elements of X are positive, and -Inf otherwise. Note that
%       LOG(PROD(X)) = SUM(LOG(X)),
%   so this is simply a synonym for SUM_LOG(X).
%
%   For matrices, LOG_PROD(X) is a row vector containing the application of
%   LOG_PROD to each column. For N-D arrays, the LOG_PROD is applied to the
%   first non-singleton dimension of X.
%
%   LOG_PROD(X,DIM) takes the product along the dimension DIM of X.
%
%   Disciplined convex programming information:
%       LOG_PROD(X) is concave and nondecreasing in X. Therefore, when used
%       in CVX expressions, X must be concave. X must be real.

narginchk(1,2);
if nargin == 1,
	cvx_optval = sum_log( X );
else
	cvx_optval = sum_log( X, dim );
end

% Copyright 2005-2016 CVX Research, Inc. 
% See the file LICENSE.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.
