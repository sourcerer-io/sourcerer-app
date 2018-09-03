function y = pow_cvx( x, p, mode )

%POW_CVX   Internal cvx version.

%
% Expression type matrices
%

persistent remap_pos remap_p remap_abs remap_pwr remap_uniq
if isempty( remap_uniq ),
    remap_x1  = cvx_remap( 'real' );
    remap_x1c = cvx_remap( 'complex' );
    remap_x2  = cvx_remap( 'log-valid' )      & ~remap_x1;
    remap_x3  = cvx_remap( 'real-affine' )    & ~remap_x1;
    remap_x3c = cvx_remap( 'complex-affine' ) & ~remap_x1c;
    remap_x4  = cvx_remap( 'concave' )        & ~( remap_x1 | remap_x3 );
    remap_x5  = cvx_remap( 'convex'  )        & ~( remap_x1 | remap_x2 | remap_x3 );
    remap_x6  = cvx_remap( 'valid'   )        & ~( remap_x1 | remap_x2 | remap_x3 | remap_x4 );
    remap_p   = [1;1;1; 1; 1; 1; 1] * remap_x1  + ...
                [2;2;2; 2; 2; 2; 2] * remap_x2  + ...
                [3;5;6; 8;11;11;11] * remap_x3  + ...
                [3;5;6; 8; 0; 0; 0] * remap_x4; 
    remap_pos = [0;0;0; 1; 1; 1; 1] * remap_x1  + ...
                [0;0;0; 2; 2; 2; 2] * remap_x2  + ...
                [0;0;0; 9;11;11;11] * remap_x3  + ...
                [0;0;0; 9; 0; 0; 0] * remap_x4  + ...
                [0;0;0; 0;11;11;11] * remap_x5;
    remap_abs = [0;0;0; 1; 1; 1; 1] * ( remap_x1 | remap_x1c ) + ...
                [0;0;0; 2; 2; 2; 2] * remap_x2  + ...
                [0;0;0;10;12;12;12] * remap_x3  + ...
                [0;0;0;10;13;13;13] * remap_x3c;
    remap_pwr = [1;1;1; 1; 1; 1; 1] * remap_x1  + ...
                [2;2;2; 2; 2; 2; 2] * remap_x2  + ...
                [0;4;6; 7;11; 0;12] * remap_x3  + ...
                [0;4;6; 7; 0; 0; 0] * remap_x4  + ...
                [0;0;0; 7; 0; 0; 0] * remap_x6;
    remap_uniq = logical( [0,0,0,1,0,1,0,0,0,0,1,1,1] );
end

%
% Argument check
%

narginchk(3,3);
p = cvx_constant( p );
if nnz( isinf( p ) | isnan( p ) ),
    error( 'Second argument must be Inf or NaN.' );
end
if ~ischar( mode ) || size( mode, 1 ) ~= 1,
    error( 'Third argument must be a string.' );
end
switch mode,
    case 'power',
        cmode  = 'pos';
        remap  = remap_pwr;
    case 'pow_p',
        cmode = 'pos';
        remap  = remap_p;
    case 'pow_pos',
        cmode = 'hypo';
        remap  = remap_pos;
    case 'pow_abs',
        cmode = 'abs';
        remap  = remap_abs;
    otherwise
        error( [ 'Invalid power mode: ', mode ] );
end

%
% Check sizes
%

sx = size( x ); xs = all( sx == 1 );
sp = size( p ); ps = all( sp == 1 );
if xs,
    sy = sp;
elseif ps || isequal( sx, sp ),
    sy = sx;
else
    error( 'Matrix dimensions must agree.' );
end

%
% Determine the expression types
%

v = 1 + ( p >= 0 ) + ( p > 0 ) + ( p >= 1 ) + ( p > 1 ) .* ( 1 + ( rem( p, 1 ) == 0 ) + ( rem( p, 2 ) == 0 ) );
v = remap( v(:)' + size(remap,1) * ( cvx_classify( x ) - 1 ) );
if ~ps,
    t = remap_uniq( v + 1 );
    if any( t ),
        [ pk, pi, pj ] = unique( p( t ) ); %#ok
        vt = v( t );
        v( t ) = vt + ( reshape( pj, size(vt) ) - 1 ) / length( pk );
    end
end
    
%
% Process each type of expression one piece at a times
%

xt = x;
pt = p;
vu = sort( v(:) );
vu = vu([true;diff(vu)~=0]);
nv = length( vu );
if nv ~= 1,
    if cvx_isconstant( x ),
        y = zeros( sy );
    else
        y = cvx( sy, [] );
    end
end
for k = 1 : nv,
    
    %
    % Select the category of expression to compute
    %
    
    vk = vu( k );
    if nv ~= 1,
        t = v == vk;
        if ~xs, xt = cvx_subsref( x, t ); end
        if ~ps, pt = cvx_subsref( p, t ); end
    end
    sz = size(xt);
    nd = length(sz)+1;
    sw = sz;
    sw(nd) = 2;
    
    %
    % Perform the computations
    %
    
    vk = floor(vk);
    switch vk,
        case 0,
            % Invalid
            pt = sprintf( '%g,', unique(pt) );
            pt = [ '{', pt(1:end-1), '}' ];
            if isequal( mode, 'power' ),
                error( 'Disciplined convex programming error:\n    Illegal operation: {%s} .^ %s\n    (Consider POW_P, POW_POS, or POW_ABS instead.)', cvx_class( xt, true, true ), pt ); 
            else
                error( 'Disciplined convex programming error:\n    Illegal operation: %s( {%s}, %s )', mode, cvx_class( xt, true, true ), pt ); 
            end
        case 1,
            % Constant result
            yt = cvx( feval( mode, cvx_constant( xt ), pt ) );
        case 2,
            % Log-convex/affine/concave
            yt = exp( log( xt ) .* pt );
        case 3,
            % power( concave, p < 0 )
            % pow_p( concave, p < 0 )
            yt = [];
            cvx_begin
                epigraph variable yt(sz)
                { cat( nd, cvx_accept_concave(xt), yt ), 1 } == geo_mean_cone( sw, nd, [-pt,1], 'func' ); %#ok
            cvx_end
        case 4,
            % power( valid, 0 )
            yt = ones(sz);
        case 5,
            % pow_p( concave, 0 )
            yt = ones(sz);
            cvx_begin
                xt >= 0; %#ok
            cvx_end
        case 6,
            % pow_p( concave, 0 < p < 1 )
            yt = [];
            cvx_begin
                hypograph variable yt(sz)
                { cat( nd, cvx_accept_concave(xt), ones(sz) ), yt } == geo_mean_cone( sw, nd, [pt,1-pt], 'func' ); %#ok
            cvx_end
        case 7,
            % power( valid, 1 )
            yt = xt;
        case 8,
            % pow_p( concave, 1 )
            yt = xt;
            cvx_begin
                xt >= 0; %#ok
            cvx_end
        case 9,
            % pow_pos( affine, 1 )
            yt = max( xt, 0 );
        case 10,
            % pow_abs( affine, 1 )
            yt = abs( xt );
        case 11,
            % power( affine, p > 1, p noninteger )
            % pow_p( affine, p > 1 )
            % pow_pos( convex, p > 1 )
            yt = [];
            cvx_begin
                epigraph variable yt(sz)
                { cat( nd, yt, ones(sz) ), cvx_accept_convex(xt) } == geo_mean_cone( sw, nd, [1/pt,1-1/pt], cmode );  %#ok
            cvx_end
        case 12,
            % pow_abs( affine, p > 1 )
            % power( affine, p even )
            yt = [];
            cvx_begin
                epigraph variable yt(sz)
                { cat( nd, yt, ones(sz) ), cvx_accept_convex(xt) } == geo_mean_cone( sw, nd, [1/pt,1-1/pt], 'abs' ); %#ok 
            cvx_end
        case 13,
            % pow_abs( complex affine, p > 1 )
            yt = [];
            cvx_begin
                epigraph variable yt(sz)
                { cat( nd, yt, ones(sz) ), xt } == geo_mean_cone( sw, nd, [1/pt,1-1/pt], 'cabs' );  %#ok
            cvx_end
    end
    
    %
    % Store the results
    %
    
    if nv ~= 1,
        y = cvx_subsasgn( y, t, yt );
    elseif isequal(sz,sy),
        y = yt;
    else
        y = yt * ones(sy);
    end
    
end

% Copyright 2005-2016 CVX Research, Inc.
% See the file LICENSE.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.

