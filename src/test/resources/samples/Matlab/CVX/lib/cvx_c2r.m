function x = cvx_c2r( x, dim, cleanup_eps )

%
% Determine expansion dimension
%

sx = size( x );
if nargin < 2,
    dim = [ find( sx > 1 ), 1 ];
    dim = dim( 1 );
elseif ~isnumeric( dim ) || dim <= 0 || dim ~= floor( dim ),
    error( 'Second argument must be a dimension.' );
end
sx = [ sx, ones( 1, dim - length( sx ) ) ];
nd = length( sx );

%
% Perform the sparse case differently
%

if isnumeric( x ) && issparse( x ) && dim <= 2,
    [ rr, cc, vv ] = find( x );
    vr = real( vv );
    vi = imag( vv );
    if nargin > 2,
        ndxs = find( vr & vi );
        if ~isempty( ndxs ),
            temp = abs( vr(ndxs) ./ vi(ndxs) );
            vr(ndxs(temp<=cleanup_eps)) = 0;
            vi(ndxs(temp>=1.0./cleanup_eps)) = 0;
        end
    end
    if dim == 1,
        rr = 2 * rr; rr = [ rr - 1 ; rr ];
        cc = [ cc ; cc ];
        sx( 1 ) = 2 * sx( 1 );
    else
        cc = 2 * cc; cc = [ cc - 1 ; cc ];
        rr = [ rr ; rr ];
        sx( 2 ) = 2 * sx( 2 );
    end
    x = sparse( rr, cc, [ vr ; vi ], sx( 1 ), sx( 2 ) );
    return
end

%
% Permute if necessary
%

perm = [];
if any( sx( 1 : dim - 1 ) ~= 1 ),
    perm = [ dim, 1 : dim - 1, dim + 1 : nd ];
    x = permute( x, perm );
    sx = sx( perm );
    dim = 1;
end

%
% Perform expansion and possibly cleanup
%

x = x( : ).';
sx( dim ) = 2 * sx( dim );
xr = real( x );
xi = imag( x );
if nargin > 2,
    ndxs = find( xr & xi );
    if ~isempty( ndxs ),
        temp = abs( xr(ndxs) ./ xi(ndxs) );
        xr(ndxs(temp<=cleanup_eps)) = 0;
        xi(ndxs(temp>=1.0./cleanup_eps)) = 0;
    end
end
x = reshape( [ xr ; xi ], sx );

%
% Reverse permute if necessary
%

if ~isempty( perm ),
    x = ipermute( x, perm );
end

% Copyright 2005-2016 CVX Research, Inc. 
% See the file LICENSE.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.

