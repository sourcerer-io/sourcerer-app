function v = cvx_classify( x )

% Classifications:
% 1  - negative constant
% 2  - zero
% 3  - positive constant
% 4  - complex constant
% 5  - concave
% 6  - real affine
% 7  - convex
% 8  - complex affine
% 9  - log concave
% 10 - log affine
% 11 - log convex monomial
% 12 - log convex posynomial
% 13 - invalid

global cvx___
v = full( cvx_vexity( x ) );
v = reshape( v, 1, prod( x.size_ ) );
if isempty( x ), return; end
b = x.basis_ ~= 0;
q = sum( b, 1 );
s = b( 1, : );

tt = q == s;
if any( tt ),
    if ~isreal( x.basis_ ),
        ti = any( imag( x.basis_ ), 1 );
        v( tt & ti ) = 4;
        tt = tt & ~ti;
    end
    v( tt ) = sign( x.basis_( 1, tt ) ) + 2;
end

tt = ~tt & ~isnan( v );
if any( tt ),
    temp = v( tt );
    temp = temp + 6;
    v( tt ) = temp;
    if ~isreal( x.basis_ ),
        ti = any( imag( x.basis_ ), 1 );
        v( tt & ti ) = 8;
    end
end

tt = isnan( v );
v( tt ) = 13;

if nnz( cvx___.exp_used ),
    tt = find( ( v == 13 | v == 7 ) & q == 1 );
    if ~isempty( tt ),
        [ rx, cx, vx ] = find( x.basis_( :, tt ) );
        qq = reshape( cvx___.logarithm( rx ), size( vx ) ) & ( vx > 0 );
        v( tt( cx( qq ) ) ) = 10 + cvx___.vexity( cvx___.logarithm( rx( qq ) ) );
    end
    tt = find( v == 7 & q > 1 );
    if ~isempty( tt ),
        [ rx, cx, vx ] = find( x.basis_( :, tt ) );
        qq = ( ~reshape( cvx___.logarithm( rx ), size( vx ) ) & ( rx > 1 ) ) | vx < 0;
        tt( cx( qq ) ) = [];
        v( tt ) = 12;
    end
end

% Copyright 2005-2016 CVX Research, Inc.
% See the file LICENSE.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.
