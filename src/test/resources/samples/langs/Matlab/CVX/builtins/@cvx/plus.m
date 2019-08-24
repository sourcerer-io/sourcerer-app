function z = plus( x, y, isdiff, cheat )

%   Disciplined convex programming information for PLUS:
%      Both terms in a sum must have the same curvature. Real affine
%      expressions are both convex and concave, so they can be added to
%      any nonlinear expressions. Complex affine (or constant)
%      expressions, however, can only be added to other affine 
%      expressions. So, for example, the following sums are valid:
%         {convex}+{convex}   {concave}+{concave}   {affine}+{affine}
%      The following are not:
%         {convex}+{concave}  {convex}+{complex constant}
%   
%   Disciplined geometric programming information for PLUS:
%      Only log-convex terms may be summed; this includes positive 
%      constants, monomials, posynomials, and generalized posynomials.
%   
%   For vectors, matrices, and arrays, these rules are verified 
%   indepdently for each element.

%
% Default arguments
%

persistent remap_plus remap_minus
if nargin < 4,
    if nargin < 3,
        isdiff = false;
    end
    cheat = false;
end

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

%
% Check vexity
%

if ~cheat,
    if isempty( remap_plus ),
        temp0  = cvx_remap( 'affine'  );
        tempc  = cvx_remap( 'complex', 'complex-affine' );
        temp1  = cvx_remap( 'convex'  ) & ~temp0;
        temp1c = temp1 + tempc;
        temp2  = cvx_remap( 'concave' ) & ~temp0;
        temp2c = temp2 + tempc;
        temp3  = temp1' * temp2c + temp2' * temp1c;
        temp1  = temp1' * temp1c;
        temp2  = temp2' * temp2c;
        temp4  = ( cvx_remap( 'log-concave' ) & ~cvx_remap( 'log-affine' ) )' * +(~cvx_remap( 'zero' )) | ...
                   cvx_remap( 'invalid' )' * cvx_remap( 'valid', 'invalid' );
        temp4 = temp4 | temp4';
        remap_minus = temp4 | temp1 | temp1' | temp2 | temp2';
        remap_plus  = temp4 | temp3 | temp3';
    end
    vx = cvx_classify( x );
    vy = cvx_classify( y );
    bad = vx + size( remap_plus, 1 ) * ( vy - 1 );
    if isdiff,
        bad = remap_minus( bad );
    else
        bad = remap_plus( bad );
    end
    if nnz( bad ),
        if ~xs, x = cvx_subsref( x, bad ); end
        if ~ys, y = cvx_subsref( y, bad ); end
        if isdiff, op = '-'; else op = '+'; end
        error( 'Disciplined convex programming error:\n   Illegal operation: {%s} %s {%s}', cvx_class( x, false, true ), op, cvx_class( y, false, true ) );
    end
end

%
% Apply operation, stretching basis matrices as needed
%

if any( sz == 0 ),
    bz = sparse( 1, 0 );
else
    x  = cvx( x );
    y  = cvx( y );
    bx = x.basis_;
    by = y.basis_;
    if isdiff,
        by = -by;
    end
    if xs && ~ys,
        nz = prod( sz );
        bx = bx( :, ones( 1, nz ) );
    elseif ys && ~xs,
        nz = prod( sz );
        by = by( :, ones( 1, nz ) );
    end
    [ nx, nv ] = size( bx );
    ny = size( by, 1 );
    if nx < ny,
        if issparse( by ), bx = sparse( bx ); end
        bx = [ bx ; sparse( ny - nx, nv ) ];
    elseif ny < nx,
        if issparse( bx ), by = sparse( by ); end
        by = [ by ; sparse( nx - ny, nv ) ];
    end
    bz = bx + by;
end

%
% Construct result
%

z = cvx( sz, bz );

% Copyright 2005-2016 CVX Research, Inc.
% See the file LICENSE.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.
