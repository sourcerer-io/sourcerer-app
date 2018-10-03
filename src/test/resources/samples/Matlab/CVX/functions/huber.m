function y = huber( x, varargin )

%HUBER   Huber penalty function.
%   HUBER(X) computes the Huber penalty function
%
%       HUBER(X) = |X|^2   if |X|<=1,
%                  2|X|-1  if |X|>=1.
%
%   HUBER(X,M) is the Huber penalty function of halfwidth M, M.^2.*HUBER(X./M). 
%   M must be real and positive.
%
%   HUBER(X,M,T) computes the Huber penalty function with halfwidth M and
%   concomitant scale T:
%
%       HUBER(X,M,T) = T.*HUBER(X./T,M) if T > 0
%                      +Inf             if T <= 0
%
%   This form supports the joint estimation of regression coefficients and
%   scaling; c.f. Art B. Owen, "A robust hybrid of lasso and ridge regression",
%   techincal report, Department of Statistics, Stanford University, 2006: 
%       http://www-stat.stanford.edu/~owen/reports/hhu.pdf
%
%   For matrices and N-D arrays, the penalty function is applied to each
%   element of X independently. M and T must be compatible with X in the same
%   sense as .*: one must be a scalar, or they must have identical size.
%
%   Disciplined convex programming information:
%       HUBER is jointly convex in X and T. It is nonomonotonic in X and
%       nonincreasing in T. Therefore, when used in CVX specifications, X
%       must be affine and T must be concave (or affine). T must be real.

if ~cvx_isaffine( x ),
    error( 'Disciplined convex programming error:\n    HUBER is nonmonotonic in X, so X must be affine.', 1 ); %#ok
end
y = huber_pos( abs( x ), varargin{:} );

% Copyright 2005-2016 CVX Research, Inc. 
% See the file LICENSE.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.
