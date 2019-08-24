function z = matrix_frac( x,Y )

%MATRIX_FRAC   Matrix fractional function.
%     MATRIX_FRAC(x,Y), where Y is a square matrix and x is a vector of the
%     same size, computes x'*(inv(Y)*x) if Y is Hermitian positive definite, and
%     +Inf otherwise.
%
%     An error results if Y is not a square matrix, or the size of
%     the vector x does not match the size of matrix Y.
%
%     Disciplined convex programming information:
%         MATRIX_FRAC is convex and nonmonotonic (at least with respect to
%         elementwise comparison), so its argument must be affine.

narginchk(2,2);
if ndims( Y ) > 2 || size( Y, 1 ) ~= size( Y, 2 ), %#ok
    error( 'Second argument must be a square matrix.' );
end
err = Y - Y';
Y   = 0.5 * ( Y + Y' );
if norm( err, 'fro' ) > 8 * eps * norm( Y, 'fro' ),
    z = Inf;
else
    [R,p] = chol(Y);
    if p > 0,
        [V,D] = eig(full(Y));
        D = diag(D);
        if any( D <= 0 )
            z = Inf;
        else
            z = V' * x;
            z = z' * ( D .\ z );
        end
    else
        z = R' \ x;
        z = z' * z;
    end
end

% Copyright 2005-2016 CVX Research, Inc.
% See the file LICENSE.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.
