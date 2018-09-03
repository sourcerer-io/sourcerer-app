function cvx_optval = lambda_max( x )

%LAMBDA_MAX   Internal cvx version.

narginchk(1,1);
if ndims( x ) > 2 || size( x, 1 ) ~= size( x, 2 ), %#ok

    error( 'Input must be a square matrix.' );

elseif cvx_isconstant( x ),

    cvx_optval = cvx( lambda_max( cvx_constant( x ) ) );

elseif cvx_isaffine( x ),

	z = [];
    n = size( x, 1 );
    cvx_begin
        epigraph variable z
        z * eye( n ) - x == semidefinite( n, ~isreal( x ) ); %#ok
    cvx_end

else

    error( 'Discipliend convex programming error:\n    LAMBDA_MAX is convex and nonmonotonic, so its input must be affine.' );

end

% Copyright 2005-2016 CVX Research, Inc.
% See the file LICENSE.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.
