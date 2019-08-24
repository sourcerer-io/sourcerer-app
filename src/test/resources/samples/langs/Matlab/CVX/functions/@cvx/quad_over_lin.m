function cvx_optval = quad_over_lin( x, y, dim )

%QUAD_OVER_LIN   Internal cvx version.

narginchk(2,3);
sx = size( x );
sy = size( y );
nx = length( sx );
ny = length( sy );
nd = max( nx, ny );
if nargin < 3 || isempty( dim ),
    dim = [ find( sx ~= 1 ), 1 ];
    dim = dim( 1 );
elseif ~isnumeric( dim ) || dim < 0 || dim ~= floor( dim ),
    error( 'Third argument must be a dimension.' );
elseif dim == 0,
    dim = nd + 1;
    nd = dim;
end

%
% Check sizes
%

sx = [ sx, ones( 1, nd - nx ) ];
sy = [ sy, ones( 1, nd - ny ) ];
sz = sx;
sz( dim ) = 1;
if sy( dim ) ~= 1 && any( sx ~= 1 ),
    error( 'Dimensions are not compatible.' );
end
if all( sz == sy ) || all( sy == 1 ),
    need_contraction = false;
elseif all( sz == 1 ),
    sz = sy;
    need_contraction = sx( dim ) ~= 1;
    sx = sz;
    dim = 0;
else
    error( 'Dimensions are not compatible.' );
end

%
% Check curvature
%

if ~cvx_isaffine( x ),
    error( 'The first argument must be affine.' );
elseif ~isreal( y ),
    error( 'The second argument must be real.' );
elseif ~cvx_isconcave( y ),
    error( 'The second argument must be concave.' );
end

%
% Construct the problem. Note that in order to support the case
% where y is convex, we actually have to introduce a new inequality
% y2 <= y, where y2 is a new variable. That is because set membership
% constraints require affine arguments. So this is an obscure case, then,
% where automatic curvature checking in epigraph functions breaks down.
%

if any( sz == 0 ),
    cvx_optval = cvx( zeros( sz ) );
elseif any( sx == 0 ),
    cvx_begin
        y == nonnegative( sz ); %#ok
    cvx_end
else
	z = [];
    cvx_begin
        epigraph variable z( sz )
        y = cvx_accept_concave( y );
        if need_contraction,
            x = cvx_accept_convex( norms( x, 2, dim ) );
        end
        { x, y, z } == rotated_lorentz( sx, dim, ~isreal( x ) ); %#ok
    cvx_end
end

% Copyright 2005-2016 CVX Research, Inc.
% See the file LICENSE.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.
