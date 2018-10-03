function [ y, symm ] = cvx_s_hankel( m, n, symm )

%CVX_S_HANKEL Hankel matrices.

c  = 0 : n - 1;
c  = c( ones( 1, m ), : );
r  = ( 0 : m - 1 )';
r  = r( :, ones( 1, n ) );
v  = abs( r + c ) + 1;
y = sparse( v, r + m * c + 1, 1, m + n + 1, m * n );
symm = false;

% Copyright 2005-2016 CVX Research, Inc. 
% See the file LICENSE.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.
