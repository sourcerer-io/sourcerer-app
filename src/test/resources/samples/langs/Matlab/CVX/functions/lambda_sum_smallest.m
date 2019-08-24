function z = lambda_sum_smallest( Y, k )

% LAMBDA_SUM_SMALLEST    Sum of the k smallest eigenvalues of a symmetric matrix.
%     For square matrix X, LAMBDA_SUM_SMALLEST(X,K) is SUM_SMALLEST(EIG(X),k)
%     if X is Hermitian or symmetric and real; and +Inf otherwise.
%
%     An error results if X is not a square matrix.
%
%     Disciplined convex programming information:
%         LAMBDA_SUM_SMALLEST is concave and nonmonotonic (at least with 
%         respect to elementwise comparison), so its argument must be affine.

z = - lambda_sum_largest( - Y, k );

% Copyright 2005-2016 CVX Research, Inc.
% See the file LICENSE.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.
