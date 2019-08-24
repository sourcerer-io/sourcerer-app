function z = kron( x, y )

%Disciplined convex/geometric programming information for KRON:
%   KRON(X,Y) computes scalar products between every element of X and
%   every element of Y. Each of those scalar products must obey the
%   DCP or DGP ruleset.

%
% Check sizes and handle cases that can be computed
% using non-Kronecker products
%

narginchk(2,2);
sx = size( x );
sy = size( y );
if length( sx ) > 2 || length( sy ) > 2,
    error( 'N-D arrays not supported.' );
elseif sx( 2 ) == 1 && ( sx( 1 ) == 1 || sy( 1 ) == 1 ),
    z = mtimes( x, y );
    return
elseif sy( 2 ) == 1 && ( sy( 1 ) == 1 || sx( 1 ) == 1 ),
    z = mtimes( y, x );
    return
else
    sz = sx .* sy;
end

%
% Expand and multiply
%

[ ix, jx, vx ] = find(x);
[ iy, jy, vy ] = find(y);
if isempty( vx ) || isempty( vy ),
    z = cvx( sparse( [], [], [], sz(1), sz(2) ) );
else
    ix = ix(:); jx = jx(:); nx = numel(ix); kx = ones(nx,1);
    iy = iy(:); jy = jy(:); ny = numel(iy); ky = ones(ny,1);
    t  = sy(1) * ( ix - 1 )';
    iz = t( ky, : ) + iy( :, kx );
    t  = sy(2) * ( jx - 1 )';
    jz = t( ky, : ) + jy( :, kx );
    z  = reshape( vy, ny, 1 ) * reshape( vx, 1, nx );
    z  = sparse( iz, jz, z, sz(1), sz(2) );
end

% Copyright 2005-2016 CVX Research, Inc.
% See the file LICENSE.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.
