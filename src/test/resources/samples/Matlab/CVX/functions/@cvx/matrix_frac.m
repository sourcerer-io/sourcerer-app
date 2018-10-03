function cvx_optval = matrix_frac( x,Y )

%MATRIX_FRAC   Internal cvx version.

narginchk(2,2);
if ndims( Y ) > 2 || size( Y, 1 ) ~= size( Y, 2 ), %#ok

    error( 'Second argument must be a square matrix.' );

elseif ndims( x ) > 2 || size( x, 2 ) > 1, %#ok

    error( 'First argument must be a column vector.' );

elseif size( x, 1 ) ~= size( Y, 1 ),

    error( 'Size of first argument (vector) must match size of second argument (matrix).' );

elseif cvx_isconstant( x ) && cvx_isconstant( Y ),

    cvx_optval = cvx( matrix_frac( cvx_constant( x ), cvx_constant(Y) ) );

elseif cvx_isaffine( x ) && cvx_isaffine( Y ),

    n = size( x, 1 );
    z = [];
    cvx_begin
        epigraph variable z
        [Y x; x' z] == semidefinite( n+1 ); %#ok
    cvx_end

else

    error( 'Disciplined convex programming error:\n    MATRIX_FRAC is convex and nonmonotonic, so its input must be affine.' );

end

% Copyright 2005-2016 CVX Research, Inc.
% See the file LICENSE.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.
