function z = rdivide( x, y )

%   Disciplined convex programming information for RDIVIDE:
%      For DCP purposes, the RDIVIDE division operator X./Y is identical
%      to X.*(1./Y). The right-hand term must be constant and non-zero;
%      and if the left-hand term is nonlinear, the constat must be real.
%   
%   Disciplined geometric programming information for RDIVIDE:
%      Terms in a left divide must have opposite log-curvature, so the
%      following products are permitted:
%         {log-convex} ./ {log-concave}  {log-concave} ./ {log-convex}
%         {log-affine} ./ {log-affine}
%      Note that log-affine expressions are both log-convex and 
%      log-concave.
%   
%   For vectors, matrices, and arrays, these rules are verified 
%   indepdently for each element.

z = times( x, y, './' );

% Copyright 2005-2016 CVX Research, Inc.
% See the file LICENSE.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.
