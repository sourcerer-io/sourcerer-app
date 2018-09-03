function y = berhu( x, M, t )

%BERHU   Reverse Huber penalty function.
%   BERHU(X) computes the reverse Huber penalty function
%
%       BERHU(X) = ABS(X)            if ABS(X)<=1,
%                  (ABS(X).^2+1)./2  if ABS(X)>=1.
%
%   BERHU(X,M) computes the reverse Huber penalty function with halfwidth M,
%   M.*BERHU(X./M). M must be real and positive.
%
%   BERHU(X,M,T) computes the reverse Huber penalty function with halfwidth M
%   and concomitant scale T: 
%
%       BERHU(X,M,T) = (M.*T).*BERHU(X./(M.*T))     if T>0
%                      +Inf                         if T<=0
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
%       BERHU is jointly convex in X and T. It is nonomonotonic in X and
%       nonincreasing in T. Therefore, when used in CVX specifications, X
%       must be affine and T must be concave (or affine). T must be real.

%
% Check arguments
%

narginchk(1,3);
if nargin < 2,
    M = 1;
elseif ~isreal( M ) || any( M( : ) <= 0 ),
    error( 'Second argument must be real and positive.' );
end
if nargin < 3,
    t = 1;
elseif ~isreal( t ),
    error( 'Third argument must be real.' );
end
sz = cvx_size_check( x, M, t );
if isempty( sz ),
    error( 'Sizes are incompatible.' );
end

%
% Compute result
%

y = abs( x ./ max(t,realmin) );
z = min( y, M );
y = t .* ( y + ( y - z ).^2 ./ (2*M) );
q = t <= 0;
if nnz( q ),
    if length(t) == 1, 
        y = Inf * ones( sz );
    else
        y( q ) = Inf;
    end
end

% Copyright 2005-2016 CVX Research, Inc.
% See the file LICENSE.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.
