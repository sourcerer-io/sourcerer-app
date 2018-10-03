function z = trace_inv( Y )

% TRACE_INV   Trace of the inverse of a PSD matrix.
%     For square matrix X, TRACE_INV(X) is TRACE(INV(X)) if X is Hermitian
%     or symmetric and positive definite; and +Inf otherwise. 
%
%     An error results if X is not a square matrix.
%
%     Disciplined convex programming information:
%         TRACE_INV is convex and nonmonotonic (at least with respect to
%         elementwise comparison), so its argument must be affine.

narginchk(1,1);
if ndims( Y ) > 2 || size( Y, 1 ) ~= size( Y, 2 ), %#ok
    error( 'Input must be a square matrix.' );
end
err = Y - Y';
Y   = 0.5 * ( Y + Y' );
if norm( err, 'fro' )  > 8 * eps * norm( Y, 'fro' ),
    z = Inf;
else
    z = eig( full( Y ) );
    if any( z <= 0 ),
        z = Inf;
    else
        z = sum(1.0./z);
    end
end

% Copyright 2005-2016 CVX Research, Inc.
% See the file LICENSE.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.

