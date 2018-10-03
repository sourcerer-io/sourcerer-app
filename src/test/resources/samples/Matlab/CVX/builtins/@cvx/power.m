function z = power( x, y )

%   Disciplined convex programming information for POWER (.^):
%      When used in CVX expressions, either X or Y must be constant. Only
%      certain convex or concave branches are accepted as valid:
%         --- if both X and Y are constant, then Z = X.^Y is interpreted
%             precisely as the MATLAB built-in version.
%         --- if Y is constant and 0 < Y < 1, then Z = X.^Y is concave and
%             nondecreasing in X. Therefore, X must be concave, and is
%             implicitly constrained to be nonnegative.
%         --- if Y is constant and Y == 1, then Z = X.
%         --- if Y is constant and a positive even integer, then Z = X.^Y
%             is convex and nonmonotonic in X. Therefore, X must be affine.
%         --- if Y is constant and Y > 1, but *not* an integer, then 
%             Z = X.^Y is convex and nonmonotonic in X. Therefore, X must
%             be affine (and real), and is implicitly constrained to be
%             nonnegative.
%      In expert mode, additional cases are handled:
%         --- if X is constant and 0 < X < 1, then Z = X.^Y is convex and
%             nonincreasing in X. Therefore, Y must be concave.
%         --- if X is constant and X == 1, then Z = 1.
%         --- if X is constant and X > 1, then Z = X.^Y is convex and
%             nondecreasing in X. Therefore, Y must be convex.
%      All other combinations are rejected as invalid. For instance, if Y
%      is an odd integer, then X .^ Y is neither convex nor concave, so it
%      is rejected. In such cases, consider using POW_P, POW_POS, or
%      POW_ABS instead.
%             
%   Disciplined geometric programming information for POWER (.^):
%      In disciplined geometric programs, the power operation Z=X.^Y is
%      valid only if Y is a real constant. There are no restrictions on
%      X. Note that a negative exponent Y reverses curvature; that is, Z
%      is log-convex if X is log-concave, and vice versa.

%
% Check sizes
%

sx = size( x ); xs = all( sx == 1 );
sy = size( y ); ys = all( sy == 1 );
if xs,
    sz = sy;
elseif ys || isequal( sx, sy ),
    sz = sx;
else
    error( 'Matrix dimensions must agree.' );
end

%
% Determine the expression types
%

if cvx_isconstant( y ),
    
    z = pow_cvx( x, y, 'power' );
    return
    
elseif ~cvx_isconstant( x ),
    
    error( 'Disciplined convex programming error:\n   In an expression X .^ Y, either X or Y must be constant.', 1 ); %#ok
    
end

%
% Now handle constant .^ non-constant
%
    
persistent remap
if isempty( remap ),
	remap_y1 = cvx_remap( 'real-affine' );
	remap_y2 = cvx_remap( 'convex' )    & ~remap_y1;
	remap_y3 = cvx_remap( 'concave' )   & ~remap_y1;
	remap_y4 = cvx_remap( 'log-valid' ) & ~( remap_y1 | remap_y2 | remap_y3 );
	remap    = [0;0;2;2;2] * remap_y1 + ...
	           [0;0;0;2;2] * remap_y2 + ...
	           [0;0;2;2;0] * remap_y3 + ...
	           [0;1;0;2;0] * remap_y4;
end
x  = cvx_constant( x );
vy = cvx_classify( y );
vx = 1 + isreal( x ) .* ( ( x >= 0 ) + ( x > 0 ) + ( x >= 1 ) + ( x > 1 ) );
vr = remap( vx + size( remap, 1 ) * ( vy - 1 ) );
vu = sort( vr(:) );
vu = vu([true;diff(vu)~=0]);
nv = length( vu );

%
% Perform the individual computations and combine
%

x = cvx( x ); xt = x;
y = cvx( y ); yt = y;
if nv ~= 1,
    z = cvx( sz, [] );
end
for k = 1 : nv,

    %
    % Select the category of expression to compute
    %

    if nv ~= 1,
        t = vr == vu( k );
        if ~xs, xt = cvx_subsref( x, t ); sz = size( xt ); end
        if ~ys, yt = cvx_subsref( y, t ); sz = size( yt ); end
    end

    %
    % The computational kernels
    %

    switch vu( k ),
        case 0,
            % Invalid
            error( 'Disciplined convex programming error:\n    Cannot perform the operation {%s}.^{%s}', cvx_class( xt, true, true, true ), cvx_class( yt, true, true, true ) );
        case 1,
            % zero .^ convex
            cvx_optval = cvx( zeros( sz ) );
        case 2,
            % (0<x<1) .^ concave, (x>1) .^ convex
            cvx_optval = exp( log( cvx_constant( xt ) ) .* yt );
        otherwise,
            error( 'Shouldn''t be here.' );
    end

    %
    % Store the results
    %

    if nv == 1,
        z = cvx_optval;
    else
        z = cvx_subsasgn( z, t, cvx_optval );
    end

end

% Copyright 2005-2016 CVX Research, Inc.
% See the file LICENSE.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.
