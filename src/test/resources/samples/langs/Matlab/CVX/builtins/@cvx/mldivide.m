function z = mldivide( x, y )

%   Disciplined convex/geomtric programming information for MLDIVIDE:
%      The MLDIVIDE operation X\Y can be employed with X as a scalar. In
%      that case, it is equivalent to the LDIVIDE operation X.\Y, and 
%      must obey the same rules as outlined in the help for CVX/LDIVIDE.
%   
%      When X is a matrix, the MRDIVIDE operation X\Y is equivalent to
%      inv(X)*Y for both DCP and DGP purposes. The inv() operation is 
%      not supported for non-constant expressions, so X must be both 
%      constant and nonsingular. The resulting matrix multiplication 
%      must obey the same rules as outlined in the help for CVX/MTIMES.

z = mtimes( x, y, 'ldivide' );

% Copyright 2005-2016 CVX Research, Inc.
% See the file LICENSE.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.
