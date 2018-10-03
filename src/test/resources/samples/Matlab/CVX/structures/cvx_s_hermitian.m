function [ y, symm ] = cvx_s_hermitian( m, n, symm ) %#ok

%CVX_S_HERMITIAN Complex Hermitian matrices. This is no longer used by
%cvx_create_structure, but it is used by cvx_sdpt3.

if m ~= n,
    error( 'Hermitian structure requires square matrices.' );
end

nsq = n * n;
c  = 0 : n - 1;
c  = c( ones( 1, 2 * n ), : );
c  = c( : );
r  = 0 : n - 1;
r  = r( [ 1, 1 ], : );
r  = r( : );
r  = r( :, ones( 1, n ) );
r  = r( : );
v  = [ 1 ; 1i ];
v  = v( :, ones( 1, nsq ) );
v  = v( : );
temp = r < c;
v( temp ) = conj( v( temp ) );
temp = r == c;
v( temp ) = real( v( temp ) );
mn = min( r, c );
mx = max( r, c );
y  = sparse( 2 * ( mx + mn .* ( n - 0.5 * ( mn + 1 ) ) + 1 ) - ( v == 1 ), r + n * c + 1, v, length( v ), nsq );
y  = y( any( y, 2 ), : );
symm = false;

% Copyright 2005-2016 CVX Research, Inc. 
% See the file LICENSE.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.
