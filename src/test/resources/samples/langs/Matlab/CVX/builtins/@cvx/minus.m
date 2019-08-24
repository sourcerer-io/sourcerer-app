function z = minus( x, y, cheat )

%   Disciplined convex programming information for MINUS:
%      Terms in a difference must have opposite curvature. Real affine
%      expressions are both convex and concave, so they can be involved
%      in a difference with any nonlinear expression. Complex affine (or
%      constant) expressions, however, are neither, so they can only be
%      involved in differences with other affine expressions. So, for
%      example, the following differences are valid:
%         {convex}-{concave}   {concave}-{convex}   {affine}-{affine}
%      The following are not:
%         {convex}-{concave}  {convex}-{complex constant}
%      For vectors, matrices, and arrays, these rules are verified
%      independently for each element.
%   
%   Disciplined geometric programming information for MINUS:
%      Non-constant expressions (log-convex or log-concave) may not be
%      involved in a subtraction in disciplined geometric programs.

if nargin < 3, cheat = false; end
z = plus( x, y, true, cheat );

% Copyright 2005-2016 CVX Research, Inc.
% See the file LICENSE.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.

