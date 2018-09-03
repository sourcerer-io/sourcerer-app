function cvx_optval = lambda_sum_largest( x, k )

%LAMBDA_SUM_LARGEST   Internal cvx version.

narginchk(2,2);
n = size( x, 1 );
if ndims( x ) > 2 || n ~= size( x, 2 ), %#ok

    error( 'First input must be a square matrix.' );
    
elseif ~isnumeric( k ) || numel( k ) ~= 1 || ~isreal( k ),
    
    error( 'Second input must be a constant real scalar.' );

elseif cvx_isconstant( x ),

    cvx_optval = cvx( lambda_max( cvx_constant( x ), k ) );
    
elseif ~cvx_isaffine( x ),

    error( 'Discipliend convex programming error:\n    LAMBDA_SUM_LARGEST is convex and nonmonotonic, so its input must be affine.' );
    
elseif k <= 0,
    
    cvx_optval = 0;
    
elseif k >= size( x, 1 ),
    
    cvx_optval = trace( x );
    
else
    
    S = [];
    cvx_begin
        variable S(n,n) symmetric
        S == semidefinite(n); %#ok
        minimize( k * lambda_max( x - S ) + trace( S ) );
    cvx_end

end

% Copyright 2005-2016 CVX Research, Inc.
% See the file LICENSE.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.
