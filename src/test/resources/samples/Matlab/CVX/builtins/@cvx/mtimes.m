function z = mtimes( x, y, oper )

%   Disciplined convex programming information for MTIMES:
%      True matrix multiplications Z = X * Y---that is, where neither X
%      nor Y is a scalar---require both multiplications and additions. 
%      For example, element (i,j) of Z is given by
%         X(i,1) * Y(1,j) + X(i,2) * Y(2,j) + ... + X(i,k) * Y(k,j)
%      Therefore, matrix multiplications must satisfy *both* the 
%      "no-product" rule of multiplication and the "same curvature" rule
%      of addition. See the help for CVX/TIMES and CVX/PLUS, 
%      respectively, for individual descriptions of these rules.
%   
%      An exception is made to these general rules for quadratic forms.
%      That is, two affine expressions may be multiplied together if the
%      result can immediately be verified as a convex quadratic form. 
%      For example, the construction
%         variable x(n)
%         x' * Q * x  <= 1;
%      would be permitted if Q is *constant* and positive semidefinite.
%   
%   Disciplined geometric programming information for TIMES:
%      As mentioned above, true matrix multiplies Z = X * Y require both
%      multiplications and additions. Since only log-convex terms can be
%      summed, both X and Y must be elementwise log-convex/affine.

persistent remap
if nargin < 3, oper = 'times'; end

%
% Check sizes
%

sx = size( x );
sy = size( y );
if all( sx == 1 ) || all( sy == 1 ),
    z = feval( oper, x, y );
    return
elseif length( sx ) > 2 || length( sy ) > 2,
    error( 'Input arguments must be 2-D.' );
elseif sx( 2 ) ~= sy( 1 ),
    error( 'Inner matrix dimensions must agree.' );
else
    sz = [ sx( 1 ), sy( 2 ) ];
end
nz = prod( sz );

%
% Check expression types
%

if cvx_isconstant( x ),
    
    xC = cvx_constant( x );
    if nnz( isnan( xC ) ),
        error( 'Disciplined convex programming error:\n    Invalid numeric values (NaNs) may not be used in CVX expressions.', 1 ); %#ok
    elseif cvx_isconstant( y ),
        yC = cvx_constant( y );
        if nnz( isnan( yC ) ),
            error( 'Disciplined convex programming error:\n    Invalid numeric values (NaNs) may not be used in CVX expressions.', 1 ); %#ok
        end
        z = feval( [ 'm', oper ], xC, yC );
        if nnz( isnan( z ) ),
            error( 'Disciplined convex programming error:\n    This expression produced one or more invalid numeric values (NaNs).', 1 ); %#ok
        end
        z = cvx( z );
        return
    elseif isequal( oper, 'rdivide' ),
        error( 'Disciplined convex programming error:\n    Matrix divisor must be constant.', 1 ); %#ok
    end
    yA   = cvx_basis( y );
    laff = true;
    cnst = false;
    raff = false;
    quad = false;
    posy = false;
    vpos = false;
    
elseif cvx_isconstant( y ),

    yC = cvx_constant( y );
    if nnz( isnan( yC ) ),
        error( 'Disciplined convex programming error:\n    Invalid numeric values (NaNs) may not be used in CVX expressions.', 1 ); %#ok
    elseif isequal( oper, 'ldivide' ),
        error( 'Disciplined convex programming error:\n    Matrix divisor must be constant.', 1 ); %#ok
    end
    xA   = cvx_basis( x );
    raff = true;
    laff = false;
    quad = false;
    cnst = false;
    posy = false;
    vpos = false;
    
else

    if isempty( remap ),
        remap_0 = cvx_remap( 'zero' );
        remap_1 = cvx_remap( 'nonzero', 'complex' );
        temp    = ~( remap_0 | remap_1 );
        remap_2 = cvx_remap( 'affine' ) & temp;
        remap_4 = cvx_remap( 'log-convex' );
        remap_5 = cvx_remap( 'log-concave' ) & ~remap_4;
        remap_4 = remap_4 & temp;
        remap_3 = cvx_remap( 'valid' ) & ~( remap_0 | remap_1 | remap_2 | remap_4 | remap_5 );
        remap   = remap_1 + 2 * remap_2 + 3 * remap_3 + 4 * remap_4 + 5 * remap_5 - cvx_remap( 'invalid' );
    end
    vx = remap( cvx_classify( x ) );
    vy = remap( cvx_classify( y ) );
    xA = cvx_basis( x );
    yA = cvx_basis( y );
    xC = cvx_reshape( xA( 1, : ), sx );
    yC = cvx_reshape( yA( 1, : ), sy );
    vx = reshape( vx, sx );
    vy = reshape( vy, sy );
    cx = xC ~= 0;
    cy = yC ~= 0;
    ax = vx == 2;
    ay = vy == 2;
    px = vx == 4;
    py = vy == 4;
    gx = vx == 5;
    gy = vy == 5;
    quad = +ax * +ay;
    if nnz( quad ) ~= 0,
        if length( quad ) ~= 1,
            error( 'Disciplined convex programming error:\n    Only scalar quadratic forms can be specified in CVX\n.', 1 ); %#ok
        else
            cx = cx & ~ax;
            cy = cy & ~ay;
            xC( ax ) = 0;
            yC( ay ) = 0;
        end
    end
    cnst = +cx * +cy; %#ok
    laff = +cx * +( vy > 1 );
    raff = +( vx > 1 ) * cy;
    posy = +px * +py;
    vpos = +gx * +gy;
    if nnz( raff ) ~= 0,
        raff = true;
        cnst = false;
    elseif nnz( laff ) ~= 0,
        laff = true;
        cnst = false;
    else
        laff = false;
        raff = false;
        cnst = true;
    end
    othr = +( vx > 1 | vx < 0 ) * +( vy > 1 | vy < 0 ) - quad - posy - vpos;
    if nnz( othr ) ~= 0,
        error( 'Disciplined convex programming error:\n    Cannot perform the operation {%s}*{%s}', cvx_class( x ), cvx_class( y ) );
    end
    quad = nnz( quad ) ~= 0;
    posy = nnz( posy ) ~= 0;
    
end

first = true;

if cnst,
    switch oper,
    case 'ldivide', z2 = xC \ yC;
    case 'rdivide', z2 = xC / yC;
    otherwise,      z2 = xC * yC;
    end
    if first, z = z2; first = false; else z = z + z2; end %#ok
end

if raff,
    % everything * constant
    nA = size( xA, 1 );
    z2 = cvx_reshape( xA, [ nA * sx( 1 ), sx( 2 ) ] );
    if issparse( z2 ),
        tt = any( z2, 2 );
        if cvx_use_sparse( size( z2 ), nnz( tt ) * sx( 2 ), isreal( z2 ) & isreal( yC ) ),
            z2 = z2( tt, : );
        else
            tt = [];
        end
    else
        tt = [];
    end
    switch oper,
    case 'rdivide', z2 = z2 / yC;
    otherwise,      z2 = z2 * yC;
    end
    z2 = cvx_reshape( z2, [ nA, nz ], tt );
    z2 = cvx( sz, z2 );
    if first, z = z2; first = false; else z = z + z2; end
end

if laff,
    % constant * everything
    nA = size( yA, 1 );
    t1 = reshape( 1 : prod( sy ), sy )';
    t2 = reshape( 1 : prod( sz ), [ sz(2), sz(1) ] )';
    z2 = yA; if raff, z2( 1, : ) = 0; end
    z2 = cvx_reshape( z2, [ nA * sy( 2 ), sy( 1 ) ], [], t1 );
    if issparse( z2 ),
        tt = any( z2, 2 );
        if cvx_use_sparse( size( z2 ), nnz( tt ) * sy( 1 ), isreal( z2 ) & isreal( xC ) ),
            z2 = z2( tt, : );
        else
            tt = [];
        end
    else
        tt = [];
    end
    switch oper,
    case 'ldivide', z2 = z2 / xC.';
    otherwise,      z2 = z2 * xC.';
    end
    z2 = cvx_reshape( z2, [ nA, nz ], tt, [], t2 );
    z2 = cvx( sz, z2 );
    if first, z = z2; first = false; else z = z + z2; end
end

if quad,
    % affine * affine
    tt = ax( : ) & ay( : );
    xA = xA( :, tt ); xB = xA( 1, : ); xA( 1, : ) = 0;
    yA = yA( :, tt ); yB = yA( 1, : ); yA( 1, : ) = 0;
    xM = size( xA, 1 ); yM = size( yA, 1 );
    if xM < yM, xA( yM, end ) = 0;
    elseif yM < xM, yA( xM, end ) = 0; end
    %
    % Quadratic form test 1: See if x == a conj( y ) + b for some real a, b,
    % so that the quadratic form involves a simple squaring (or sum of squares)
    %
    cyA   = conj( yA );
    alpha = sum( sum( real( xA .* yA ) ) ) ./ max( sum( sum( cyA .* yA ) ), realmin );
    if sum( sum( abs( xA - alpha * cyA ) ) ) <= 2 * eps * sum( sum( abs( xA ) ) ),
        beta = xB - alpha * conj( yB );
        yt = cvx( [ 1, size( yA, 2 ) ], yA ) + yB;
        if isreal( yA ) && isreal( yB ) && isreal( beta ),
            beta = ( 0.5 / alpha ) * beta;
            z2 = alpha * ( sum_square( yt + beta ) - sum_square( beta ) );
        elseif all( abs( beta ) <= 2 * eps * abs( xB ) ),
            z2 = alpha * sum_square_abs( yt );
        else
            error( 'Disciplined convex programming error:\n    Invalid quadratic form: product is not real.\n', 1 ); %#ok
        end
    else
        %
        % Quadratic form test 2: Extract the quadratic coefficient matrix
        % and test it for semidefiniteness
        %
        dx = find( any( xA, 2 ) | any( yA, 2 ) );
        zb = length( dx );
        cxA = conj( xA( dx, : ) );
        cyA = cyA( dx, : );
        P  = cxA * cyA.';
        Q  = cxA * yB.' + cyA * xB.';
        R  = xB * yB.';
        P  = 0.5 * ( P + P.' );
        if ~isreal( R ) || ~isreal( Q ) || ~isreal( P ),
            error( 'Disciplined convex programming error:\n   Invalid quadratic form: product is complex.', 1 ); %#ok
        else
            xx = cvx( zb, sparse( dx, 1 : zb, 1 ) );
            [ z2, success ] = quad_form( xx, P, Q, R );
            if ~success,
                error( 'Disciplined convex programming error:\n   Invalid quadratic form: neither convex nor concave.', 1 ); %#ok
            end
        end
    end
    if first, z = z2; first = false; else z = z + z2; end
end

if posy,
    [ ix, jx ] = find( reshape( px, sx ) );
    vx = log( cvx_subsref( x, px ) );
    [ iy, jy ] = find( reshape( py, sy ) );
    vy = log( cvx_subsref( y, py ) );
    [ iz, jz ] = find( sparse( 1 : nnz(px), jx, 1 ) * sparse( iy, 1 : nnz(py), 1 ) );
    z2 = exp( vec( cvx_subsref( vx, iz ) ) + vec( cvx_subsref( vy, jz ) ) );
    z2 = sparse( ix(iz), jy(jz), z2, sz(1), sz(2) );
    if first, z = z2; first = false; else z = z + z2; end
end

if vpos,
    [ ix, jx ] = find( reshape( gx, sx ) );
    vx = log( cvx_subsref( x, gx ) );
    [ iy, jy ] = find( reshape( gy, sy ) );
    vy = log( cvx_subsref( y, gy ) );
    [ iz, jz ] = find( sparse( 1 : nnz(gx), jx, 1 ) * sparse( iy, 1 : nnz(gy), 1 ) );
    z2 = exp( vec( cvx_subsref( vx, iz ) ) + vec( cvx_subsref( vy, jz ) ) );
    z2 = sparse( ix(iz), jy(jz), z2, sz(1), sz(2) );
    if first, z = z2; first = false; else z = z + z2; end %#ok
end

%
% Check that the sums are legal
%

v = cvx_vexity( z );
if any( isnan( v( : ) ) ),
    temp = 'Disciplined convex programming error:';
    tt = isnan( cvx_constant( z ) );
    if any( tt ),
        temp = [ temp, '\n    This expression produced one or more invalid numeric values (NaNs).' ];
    end
    if any( isnan( v( ~tt ) ) ),
        temp = [ temp, '\n   Illegal affine combination of convex and/or concave terms detected.' ];
    end
    error( temp, 1 ); 
end

% Copyright 2005-2016 CVX Research, Inc.
% See the file LICENSE.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.
