function y = log_normcdf( x, approx ) %#ok

%LOG_NORMCDF   Logarithm of the cumulative normal distribution.
%   Y = LOG_NORMCDF(X) is the logarithm of the CDF of the normal
%   distribution at the point X.
%
%                                1    / x
%       LOG_NORMCDF(X) = LOG( ------- |   exp(-t^2/2) dt )
%                             sqrt(2) / -Inf
%
%   For numeric X, LOG_NORMCDF(X) is computed using the equivalent 
%   expression LOG(0.5*ERFC(-X*SQRT(0.5))). When X is a CVX variable, a 
%   a piecewise quadratic *approximation* is employed instead. This
%   approximation gives good results when -4 <= x <= 4, and will be
%   improved in future releases of CVX.
%
%   For array values of X, the LOG_NORMCDF returns an array of identical
%   size with the calculation applied independently to each element.
%
%   X must be real.
%
%   Disciplined convex programming information:
%       LOG_NORMCDF is concave and nondecreasing in X. Therefore, when used
%       in CVX specifications, X must be concave.

narginchk(1,2);
if ~isreal( x ),
    error( 'Argument must be real.' );
end
if nargin > 1,
    % For debugging purposes only
    y = cvx_constant(log_normcdf(cvx(x)));
else
    y = log(0.5*erfc(-x*sqrt(0.5)));
end

% Copyright 2005-2016 CVX Research, Inc. 
% See the file LICENSE.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.
