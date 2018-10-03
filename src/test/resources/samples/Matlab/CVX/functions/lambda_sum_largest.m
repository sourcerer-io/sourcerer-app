function z = lambda_sum_largest( Y, k )

% LAMBDA_SUM_LARGEST   Sum of the k largest eigenvalues of a symmetric matrix.
%
%     For square matrix X, LAMBDA_SUM_LARGEST(X,K) is SUM_LARGEST(EIG(X),k)
%     if X is Hermitian or symmetric and real; and +Inf otherwise.
%
%     An error results if X is not a square matrix.
%
%     Disciplined convex programming information:
%         LAMBDA_SUM_LARGEST is convex and nonmonotonic (at least with 
%         respect to elementwise comparison), so its argument must be affine.

narginchk(2,2);
if ndims( Y ) > 2 || size( Y, 1 ) ~= size( Y, 2 ), %#ok
    error( 'First input must be a square matrix.' );
elseif ~isnumeric( k ) || numel( k ) ~= 1 || ~isreal( k ),
    error( 'Second input must be a real scalar.' );
end
err = Y - Y';
Y   = 0.5 * ( Y + Y' );
if norm( err, 'fro' )  > 8 * eps * norm( Y, 'fro' ),
    z = Inf;
else
    z = sum_largest( eig( full( Y ) ), k );
end

% Copyright 2005-2016 CVX Research, Inc.
% See the file LICENSE.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.
