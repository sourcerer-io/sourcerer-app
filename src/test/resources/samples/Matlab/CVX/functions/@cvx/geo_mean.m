function y = geo_mean( x, dim, w )
narginchk(1,3);

%GEO_MEAN   Internal cvx version.

%
% Size check
%

try
    if nargin < 2, dim = []; end
    [ x, sx, sy, zx, zy, nx, nv, perm ] = cvx_reduce_size( x, dim ); %#ok
catch exc
    rethrow( exc )
end
    
%
% Third argument check
%

if nargin < 3 || isempty( w ),
    w = [];
elseif numel( w ) ~= length( w ) || ~isnumeric( w ) || ~isreal( w ) || any( w < 0 ) || any( w ~= floor( w ) ),
    error( 'Third argument must be a vector of nonnegative integers.' );
elseif length( w ) ~= nx,
    error( 'Third argument must be a vector of length %d', nx );
end

%
% Quick exit for simple cases
%

if isempty( x ) || ~isempty( w ) && ~any( w ),
    y = ones( zy );
    return
end

%
% Type check
%

persistent remap_1 remap_2 remap_3 remap_4
if isempty( remap_4 ),
    % Constant (postive or negative)
    remap_1 = cvx_remap( 'real' );
    remap_2 = cvx_remap( 'concave' );
    remap_3 = cvx_remap( 'log-convex' );
    remap_4 = cvx_remap( 'log-concave' );
end
vx = cvx_reshape( cvx_classify( x ), sx );
t1 = all( reshape( remap_1( vx ), sx ) );
t2 = all( reshape( remap_2( vx ), sx ) );
t3 = all( reshape( remap_3( vx ), sx ) ) | ...
     all( reshape( remap_4( vx ), sx ) );
% Valid combinations with zero or negative entries can be treated as constants
t1 = t1 | ( ( t2 | t3 ) & any( vx == 1 | vx == 9 ) );
ta = t1 + ( 2 * t2 + 3 * t3 ) .* ~t1;
nu = sort( ta(:) );
nu = nu([true;diff(nu)~=0]);
nk = length( nu );

%
% Perform the computations
%

if nk > 1,
    y = cvx( [ 1, nv ], [] );
end
for k = 1 : nk,

    if nk == 1,
        xt = x;
    else
        tt = ta == nu( k );
        xt = cvx_subsref( x, ':', tt );
    end

    switch nu( k ),
        case 0,
            error( 'Disciplined convex programming error:\n   Invalid computation: geo_mean( {%s} )', cvx_class( xt, true, true ) );
        case 1,
            yt = cvx( geo_mean( cvx_constant( xt ), 1, w ) );
        case 2,
        	yt = [];
            cvx_begin
                hypograph variable yt(1,nv);
                { cvx_accept_concave(xt), yt } == geo_mean_cone( size(xt), 1,  w, 'func' ); %#ok
            cvx_end
        case 3,
            if nx == 1,
                yt = xt;
            elseif isempty( w ),
                yt = exp( sum( log( xt ), 1 ) * ( 1 / nx ) );
            else
                yt = exp( ( w / sum( w ) ) * log( xt ) );
            end
        otherwise,
            error( 'Shouldn''t be here.' );
    end

    if nk == 1,
        y = yt;
    else
        y = cvx_subsasgn( y, tt, yt );
    end

end

%
% Reverse the reshaping and permutation steps
%

y = reshape( y, sy );
if ~isempty( perm ),
    y = ipermute( y, perm );
end

% Copyright 2005-2016 CVX Research, Inc.
% See the file LICENSE.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.
