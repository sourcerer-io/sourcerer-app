function y = blkdiag( varargin )

%Disciplined convex/geometric programming information for BLKDIAG:
%   BLKDIAG imposes no convexity restrictions on its arguments.

nv = 0;
nz = 0;
sz = [ 0, 0 ];
for k = 1 : nargin,
    x  = cvx( varargin{k} );
    sx = x.size_;
    if length( sx ) > 2,
        error( 'N-D matrices not supported.' );
    end
    b  = x.basis_;
    sz = sz + sx;
    nv = max( nv, size( b, 1 ) );
    nz = nz + nnz( b );
    varargin{k} = x;
end
bz = sparse( [], [], [], prod( sz ), nz, nv );
roff = 0;
coff = 0;
for k = 1 : nargin,
    x  = varargin{k};
    b  = x.basis_;
    sx = x.size_;
    ndxr = ( roff : roff + sx( 1 ) - 1 )';
    ndxr = ndxr( :, ones( 1, sx( 2 ) ) );
    ndxc = ( coff : coff + sx( 2 ) - 1 );
    ndxc = ndxc( ones( 1, sx( 1 ) ), : );
    bz( 1 : size( b, 1 ), ndxc( : ) * sz( 1 ) + ndxr( : ) + 1 ) = b; %#ok
    roff = roff + sx( 1 );
    coff = coff + sx( 2 );
end
y = cvx( sz, bz );

% Copyright 2005-2016 CVX Research, Inc.
% See the file LICENSE.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.
