function [ x, sx, sy, zx, zy, nx, nv, perm ] = cvx_reduce_size( x, dim, do_reduce )

%
% Reduction dimension
%

zx = size( x );
if isempty( dim ),
    dim = find( zx ~= 1, 1, 'first' );
    if isempty( dim ), dim = 1; end
elseif ~isnumeric( dim ) || numel( dim ) ~= 1 || ~isreal( dim ) || dim <= 0 || isinf(dim) || isnan(dim) || dim ~= floor(dim),
    error( 'Dimension argument must be a positive integer.' );
end

%
% Vector size, reduction size, number of vectors
%

nd = max( dim, length( zx ) );
zx( end + 1 : nd ) = 1;
nx = zx( dim );
zy = zx;
if nargin < 3 || do_reduce, zy( dim ) = 1; end
nl = prod( zy( 1 : dim -1  ) );
nr = prod( zy( dim + 1 : end ) );
nv = nl * nr;

%
% Permute if needed
%

if nl * nx > 1,
    perm = [ dim, 1 : dim - 1, dim + 1 : nd ];
    x    = permute( x,  perm );
    sx   = zx( perm );
    sy   = zy( perm );
else
    perm = [];
    sx   = zx;
    sy   = zy;
end

%
% Reshape
%

x = reshape( x, nx, nv );

% Copyright 2005-2016 CVX Research, Inc. 
% See the file LICENSE.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.
