function y = square( x )

%SQUARE    Square.
%   SQUARE(X) is an array of the same size as X, whose elements are the
%   squares of the elements of X.
%
%   Disciplined convex programming information:
%       If X is real, then SQUARE(X) is convex and nonmonotonic in X. If X
%       is complex, then SQUARE(X) is neither convex nor concave. Thus when
%       when use in CVX expressions, X must be real and affine.

narginchk(1,1);
y = x .* x;

% Copyright 2005-2016 CVX Research, Inc. 
% See the file LICENSE.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.
