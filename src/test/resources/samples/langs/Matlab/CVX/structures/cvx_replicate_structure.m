function str = cvx_replicate_structure( str, sz )
%CVX_REPLICATE_STRUCTURE Apply matrix structure to N-D arrays.

szs  = size( str );
nmat = prod( sz );
omat = ones( 1, nmat );
[ r, c, v ] = find( str );
nelm = length( r );
oelm = ones( 1, nelm );
r = r( : );
nvec = ( 0 : nmat - 1 ) * szs( 1 );    
r = r( :, omat ) + nvec( oelm, : );
c = c( : );
c = c( :, omat );
nvec = ( 0 : nmat - 1 ) * szs( 2 );
c = c( :, omat ) + nvec( oelm, : );
v = v( : );
v = v( :, omat );
str = sparse( r, c, v, nmat * szs( 1 ), nmat * szs( 2 ) );

% Copyright 2005-2016 CVX Research, Inc. 
% See the file LICENSE.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.
