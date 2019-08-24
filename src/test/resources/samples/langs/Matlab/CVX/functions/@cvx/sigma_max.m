function cvx_optval = sigma_max( x )

%SIGMA_MAX   Internal cvx version.

narginchk(1,1);
if ndims( x ) > 2, %#ok
    error( 'lambda_max is not defined for N-D arrays.' );
elseif ~cvx_isaffine( x ),
    error( 'Input must be affine.' );
end

%
% Construct problem
% 

[ m, n ] = size( x );
cvx_optval = lambda_max( [ zeros( m, m ), x ; x', zeros( n, n ) ] );

% Copyright 2005-2016 CVX Research, Inc. 
% See the file LICENSE.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.
