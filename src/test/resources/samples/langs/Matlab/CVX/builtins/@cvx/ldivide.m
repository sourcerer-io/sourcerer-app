function z = ldivide( x, y )

%Disciplined convex programming information for LDIVIDE:
%   For DCP purposes, the LDIVIDE division operator X.\Y is equivalent to
%   (1./X).*Y. The left-hand term must be constant and non-zero; and if the
%   right-hand term is nonlinear, t constant must also be real.
%
%Disciplined geometric programming information for LDIVIDE:
%   Terms in a left divide must have opposite log-curvature, so the
%   following products are permitted:
%      {log-convex} .\ {log-concave}  {log-concave} .\ {log-convex}
%      {log-affine} .\ {log-affine}
%   Note that log-affine expressions are both log-convex and log-concave.
%
%For vectors, matrices, and arrays, these rules are verified indepdently
%for each element.

z = times( x, y, '.\' );

% Copyright 2005-2016 CVX Research, Inc.
% See the file LICENSE.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.
