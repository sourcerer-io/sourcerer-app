function z = lambda_min( Y )

% LAMBDA_MIN   Minimum eigenvalue of a symmetric matrix.
%     For square matrix X, LAMBDA_MIN(X) is MIN(EIG(X)) if X is Hermitian
%     or symmetric and real; and -Inf otherwise.
%
%     An error results if X is not a square matrix.
%
%     Disciplined convex programming information:
%         LAMBDA_MIN is concave and nonmonotonic (at least with respect to
%         elementwise comparison), so its argument must be affine.

narginchk(1,1);
z = - lambda_max( -Y );

% Copyright 2005-2016 CVX Research, Inc.
% See the file LICENSE.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.

