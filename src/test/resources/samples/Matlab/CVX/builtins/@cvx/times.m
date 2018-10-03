function z = times( x, y, oper )

%   Disciplined convex programming information for TIMES:
%      In general, disciplined convex programs must obey the "no-product
%      rule" which states that two non-constant expressions cannot be 
%      multiplied together. Under this rule, the following combinations
%      are allowed:
%         {constant} .* {non-constant}  {non-constant} .* {constant}
%      Furthermore, if the non-constant expression is nonlinear, then 
%      the constant term must be real.
%   
%      A lone exception to the no-product rule is made for quadratic 
%      forms: two affine expressions may be multiplied together if the 
%      result is convex or concave. For example, the construction
%         variable x(n)
%         x.*x  <= 1;
%      would be permitted because each element of x.*x is convex.
%   
%   Disciplined geometric programming information for TIMES:
%      Both terms in a multiplication must have the same log-curvature, 
%      so the following products are permitted:
%         {log-convex} .* {log-convex}  {log-concave} .* {log-concave}
%         {log-affine} .* {log-affine}
%      Note that log-affine expressions are both log-convex and
%      log-concave.
%   
%   For vectors, matrices, and arrays, these rules are verified 
%   indepdently for each element.

narginchk(2,3);
if nargin < 3, oper = '.*'; end

%
% Check sizes
%

sx = size( x );
sy = size( y );
xs = all( sx == 1 );
ys = all( sy == 1 );
if xs,
    sz = sy;
elseif ys,
    sz = sx;
elseif ~isequal( sx, sy ),
    error( 'Matrix dimensions must agree.' );
else
    sz = sx;
end
nn = prod( sz );
if nn == 0,
    z = zeros( sz );
    return
end

%
% Determine the computation methods
%

persistent remap_m remap_l remap_r
if isempty( remap_r ),
    % zero .* valid, valid .* zero, constant .* constant
    temp_1    = cvx_remap( 'constant' );
    temp_2    = cvx_remap( 'zero' );
    temp_3    = temp_2' * cvx_remap( 'valid' );
    remap_1   = ( temp_1' * temp_1 ) | temp_3 | temp_3';
    remap_1n  = ~remap_1;
    % constant / nonzero, zero / log-concave, zero / log-convex
    temp_4    = temp_1 & ~temp_2;
    remap_1r  = ( temp_1' * temp_4 ) | ( temp_2' * cvx_remap( 'log-valid' ) );
    remap_1rn = ~remap_1r;

    % constant * affine, real * convex/concave/log-convex, positive * log-concave
    temp_5   = cvx_remap( 'real' );
    temp_6   = cvx_remap( 'positive' );
    temp_7   = cvx_remap( 'affine' );
    temp_1n   = ~temp_1;
    temp_8   = cvx_remap( 'log-concave' ) & temp_1n;
    remap_2  = ( temp_1' * temp_7 ) | ...
               ( temp_5' * cvx_remap( 'convex', 'concave', 'log-convex' ) ) | ...
               ( temp_6' * temp_8 );
    remap_2  = remap_2 & remap_1n;
    % real / log-concave, positive / log-convex
    temp_9   = cvx_remap( 'log-convex' ) & temp_1n;
    remap_2r = ( temp_5' * temp_8 ) | ...
               ( temp_6' * temp_9 );
    remap_2r = remap_2r & remap_1rn;
           
    % Affine * constant, convex/concave/log-convex * real, log-concave * positive
    remap_3  = remap_2';
    % Affine / nonzero, convex/concave/log-convex / nzreal, log-concave / positive
    remap_3r = remap_3;
    remap_3r(:,2) = 0;
           
    % Affine * affine
    remap_4  = temp_7 & ~temp_1;
    remap_4  = remap_4' * +remap_4;

    % log-concave * log-concave, log-convex * log-convex
    remap_5  = ( temp_8' * +temp_8 ) | ( temp_9' * +temp_9 );
    % log-concave / log-convex, log-convex / log-concave
    remap_5r = temp_8' * +temp_9;
    remap_5r = remap_5r | remap_5r';
           
    remap_m = remap_1 + 2 * remap_2  + 3 * remap_3 + 4 * remap_4 + 5 * remap_5;
    remap_r = remap_1r + 2 * remap_2r + 3 * remap_3r + 5 * remap_5r;
    remap_r(:,2) = 0;
    remap_l = remap_r';
end
switch oper,
    case '.*',
        remap = remap_m;
        r_recip = 0;
        l_recip = 0;
    case './',
        remap = remap_r;
        r_recip = 1;
        l_recip = 0;
    case '.\',
        remap = remap_l;
        r_recip = 0;
        l_recip = 1;
end
vx = cvx_classify( x );
vy = cvx_classify( y );
vr = remap( vx + size( remap, 1 ) * ( vy - 1 ) );
vu = sort( vr(:) );
vu = vu([true;diff(vu)~=0]);
nv = length( vu );
if vu(1) == 1 && nv > 1,
    vr(vr==1) = vu(2); 
    nv = nv - 1;
    vu(1) = [];
end

%
% Process each computation type separately
%

x   = cvx( x );
y   = cvx( y );
xt  = x;
yt  = y;
if nv ~= 1,
    z = cvx( sz, [] );
end
for k = 1 : nv,

    %
    % Select the category of expression to compute
    %

    if nv ~= 1,
        t = vr == vu( k );
        if ~xs,
            xt = cvx_subsref( x, t );
            sz = size( xt );
        end
        if ~ys,
            yt = cvx_subsref( y, t );
            sz = size( yt );
        end
    end

    %
    % Apply the appropriate computation
    %

    switch vu( k ),
    case 0,

        % Invalid
        error( 'Disciplined convex programming error:\n    Cannot perform the operation: {%s} %s {%s}', cvx_class( xt, true, true, true ), oper, cvx_class( yt, true, true, true ) );
        
    case 1,
        
        % constant .* constant
        xb = cvx_constant( xt );
        yb = cvx_constant( yt );
        if l_recip,
            cvx_optval = xb .\ yb;
        elseif r_recip,
            cvx_optval = xb ./ yb;
        else
            cvx_optval = xb .* yb;
        end
        if nnz( isnan( cvx_optval ) ),
            error( 'Disciplined convex programming error:\n    This expression produced one or more invalid numeric values (NaNs).', 1 ); %#ok
        end
        cvx_optval = cvx( cvx_optval );

    case 2,

        % constant .* something
        xb = cvx_constant( xt );
        if l_recip, xb = 1.0 ./ xb; end
        yb = yt;
        if r_recip && nnz( xb ), yb = exp( - log( yb ) ); end
        yb = yb.basis_;
        if ~xs,
            nn = numel(  xb  );
            if ys,
                xb = cvx_reshape( xb, [ 1, nn ] );
                if issparse( yb ) && ~issparse( xb ), 
                    xb = sparse( xb ); 
                end
            else
                n1 = 1 : nn;
                xb = sparse( n1, n1, xb( : ), nn, nn );
            end
        end
        cvx_optval = cvx( sz, yb * xb );

    case 3,

        % something .* constant
        yb = cvx_constant( yt );
        if r_recip, yb = 1.0 ./ yb; end
        xb = xt;
        if l_recip && any( xb ), xb = exp( - log( xb ) ); end
        xb = xb.basis_;
        if ~ys,
            nn = numel(  yb  );
            if xs,
                yb = cvx_reshape( yb, [ 1, nn ] );
                if issparse( xb ) && ~issparse( yb ),
                    yb = sparse( yb );
                end
            else
                n1 = 1 : nn;
                yb = sparse( n1, n1, yb( : ), nn, nn );
            end
        end
        cvx_optval = cvx( sz, xb * yb );

    case 4,

        % affine .* affine
        nn = prod( sz );
        xA = xt.basis_; yA = yt.basis_;
        if xs && ~ys, xA = xA( :, ones( 1, nn ) ); end
        if ys && ~xs, yA = yA( :, ones( 1, nn ) ); end
        mm = max( size( xA, 1 ), size( yA, 1 ) );
        if size( xA, 1 ) < mm, xA( mm, end ) = 0; end
        if size( yA, 1 ) < mm, yA( mm, end ) = 0; end
        xB = xA( 1, : ); xA( 1, : ) = 0;
        yB = yA( 1, : ); yA( 1, : ) = 0;
        cyA   = conj( yA );
        alpha = sum( real( xA .* yA ), 1 ) ./ max( sum( cyA .* yA, 1 ), realmin );
        adiag = sparse( 1 : nn, 1 : nn, alpha, nn, nn );
        if all( sum( abs( xA - cyA * adiag ), 2 ) <= 2 * eps * sum( abs( xA ), 2 ) ),
            beta  = xB - alpha .* conj( yB );
            alpha = reshape( alpha, sz );
            if isreal( y ),
                cvx_optval = alpha .* square( y ) + reshape( beta, sz ) .* y;
            elseif all( abs( beta ) <= 2 * eps * abs( xB ) ),
                cvx_optval = alpha .* square_abs( y );
            else
                error( 'Disciplined convex programming error:\n    Invalid quadratic form(s): product is not real.\n', 1 ); %#ok
            end
        else
            error( 'Disciplined convex programming error:\n    Invalid quadratic form(s): not a square.\n', 1 ); %#ok
        end

    case 5,

        % posynomial .* posynomial
        xb = log( xt );
        if l_recip, xb = - xb; end
        yb = log( yt );
        if r_recip, yb = - yb; end
        cvx_optval = exp( xb + yb );

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
