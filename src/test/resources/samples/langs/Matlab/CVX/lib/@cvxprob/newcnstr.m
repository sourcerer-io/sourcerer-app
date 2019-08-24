function [ outp, sdp_mode ] = newcnstr( prob, x, y, op, sdp_mode )
persistent map_eq map_le map_ge map_ne
    
%
% Check problem
%

if ~isa( prob, 'cvxprob' ),
    error( 'A cvx problem must be created first.' );
end
global cvx___
p = prob.index_;
y_orig = y;

%
% Check for a dual reference
%

dx = cvx_getdual( x );
dy = cvx_getdual( y );
if isempty( dx ),
    dx = dy;
elseif ~isempty( dy ),
    error( [ 'Two dual variable references found: "', dx, '","', dy, '"' ] );
end
if ~isempty( dx ),
    duals = cvx___.problems( p ).duals;
    try
        dual = builtin( 'subsref', duals, dx );
    catch
        nm = cvx_subs2str( dx );
        error( [ 'Dual variable "', nm(2:end), '" has not been declared.' ] );
    end
    if ~isempty( dual ),
        nm = cvx_subs2str( dx );
        error( [ 'Dual variable "', nm(2:end), '" already in use.' ] );
    end
end

%
% Check arguments
%

if isa( x, 'cvxcnst' ), 
    x = rhs( x ); 
end
cx = isnumeric( x ) | isa( x, 'cvx' );
cy = isnumeric( y ) | isa( y, 'cvx' );
if ~cx,
    x = cvx_collapse( x, false, true );
    cx = isnumeric( x ) | isa( x, 'cvx' );
end
if ~cy,
    y = cvx_collapse( y, false, true );
    cy = isnumeric( y ) | isa( y, 'cvx' );
end
sx = size( x );
sy = size( y );
if ~cx || ~cy,
    if cx || cy || op(1) ~= '=',
        error( 'Invalid CVX constraint: {%s} %s {%s}', class( x ), op, class( y ) );
    elseif ~isequal( sx, sy ),
        error( 'The left- and right-hand sides have incompatible sizes.' );
    else
        if ~isempty( dx ),
            duals = cvx___.problems( p ).duals;
            duals = builtin( 'subsasgn', duals, dx, cell(sx) );
            cvx___.problems( p ).duals = duals;
        end
        nx = prod( sx );
        for k = 1 : nx,
            newcnstr( prob, x{k}, y{k}, op );
        end
        if nargout,
            outp = cvxcnst( prob, y_orig );
        end
        return
    end
end
xs = all( sx == 1 );
ys = all( sy == 1 );
if xs,
    sz = sy;
elseif ys || isequal( sx, sy ),
    sz = sx;
else
    error( 'Matrix dimensions must agree.' );
end

%
% Check readlevel
%

tx = cvx_readlevel( x );
ty = cvx_readlevel( y );
tx = any( tx( : ) > p );
ty = any( ty( : ) > p );
if tx || ty,
    error( 'Constraints may not involve internal, read-only variables.' );
end

%
% Handle the SDP case
%

if nargin < 5 || ~sdp_mode,
    sdp_mode = op(1) ~= '='  && cvx___.problems( p ).sdp;
end
if sdp_mode,
    mx = sx( 1 ) > 1 & sx( 2 ) > 1;
    my = sy( 1 ) > 1 & sy( 2 ) > 1;
    sdp_mode = mx || my;
end
if sdp_mode,
    
    if sx( 1 ) ~= sx( 2 ) || sy( 1 ) ~= sy( 2 ),
        error( 'SDP constraint must be square.' );
    elseif xs && cvx_isnonzero( x ),
        error( 'SDP constraint {scalar} %s {matrix} valid only if the scalar is zero.', op );
    elseif ys && cvx_isnonzero( y ),
        error( 'SDP constraint {matrix} %s {scalar} valid only if the scalar is zero.', op );
    elseif ~cvx_isaffine( x ) || ~cvx_isaffine( y ),
        error( 'Both sides of an SDP constraint must be affine.' );
    end
    zq = any( cvx_basis( x ), 1 ) | any( cvx_basis( y ), 1 );
    qn = bsxfun( @plus, (1:sz(1)+1:sz(1)*sz(2))', 0:sz(1)*sz(2):prod(sz)-1 );
    if nnz( zq ) == nnz( zq( qn ) ),
        [ tx, dummy ] = find( cvx_basis( nonnegative( numel(qn) ) ) );
        z = cvx( sz, sparse( tx, qn, 1, tx(end), prod(sz) ) );
    else
        z = semidefinite( sz, ~isreal( x ) || ~isreal( y ) );
    end
    if op(1) == '>',
        z = minus( x, plus( y, z ) );
    else
        z = minus( y, plus( x, z ) );
    end
    op = '==';

else
    
    sdp_mode = false;
    if isempty( map_ge ),
        temp    = cvx_remap( 'constant' );
        temp    = ~ ( temp' * temp );
        
        map_ne  = cvx_remap;

        map_eq2 = cvx_remap( 'log-affine' );
        map_eq2 = ( map_eq2' * map_eq2 ) & temp;
        map_eq3 = cvx_remap( 'affine' );
        map_eq3 = map_eq3' * map_eq3;
        map_eq  = 2 * map_eq2 + map_eq3;

        % Trivially feasible constraints
        map_ge1 = ( cvx_remap( 'log-concave' )' * cvx_remap( 'nonpositive' ) ) & temp;
        % Trivially infeasible constraints
        map_ge2 = ( cvx_remap( 'nonpositive' )' * cvx_remap( 'log-convex'  ) ) & temp;
        % Full geometric constraints
        map_ge3  = ( cvx_remap( 'log-concave' )' * cvx_remap( 'log-convex'  ) ) & temp;
        % Linear constraints
        map_ge4 = ( cvx_remap( 'concave' )' * cvx_remap( 'convex' ) ) & ~map_ge3;
        map_ge = map_ge4 + 2 * map_ge3 + 3 * map_ge2 + 4 * map_ge1;

        map_le = map_ge';
    end
    switch op(1),
        case '<',
            remap = map_le;
        case '>',
            remap = map_ge;
        case '~',
            remap = map_ne;
        otherwise,
            remap = map_eq;
    end
    vx = cvx_classify( x );
    vy = cvx_classify( y );
    vm = vx + size( remap, 1 ) * ( vy - 1 );
    vr = remap( vm );
    tt = vr( : ) == 0;
    if any( tt ),
        [ vu, vi ] = unique( vm );
        vi = vi( remap( vu ) == 0 );
        strs = {};
        xt = x; yt = y;
        for k = 1 : length( vi ),
            if any( sx ~= 1 ), xt = x(vi(k)); end
            if any( sy ~= 1 ), yt = y(vi(k)); end
            strs{k+1} = sprintf( '\n   Invalid constraint: {%s} %s {%s}', cvx_class( xt, false, true ), op, cvx_class( yt, false, true ) );
        end
        error( [ sprintf( 'Disciplined convex programming error:' ), strs{:} ] );
    end
    tt = vr( : ) == 2;
    if any( tt ),
        if all( tt ),
            x = log( x );
            y = log( y );
        else
            if isscalar( x ), x = x * ones(size(y)); end
            if isscalar( y ), y = y * ones(size(x)); end
            x( tt ) = log( x( tt ) );
            y( tt ) = log( y( tt ) );
        end
    end
    tt = vr( : ) == 3;
    if any( tt ),
        x( tt ) = 0;
        y( tt ) = 1 - 2 * ( op(1) == '<' );
    end
    tt = vr( : ) == 4;
    if any( tt ),
        x( tt ) = 0;
        y( tt ) = 1 - 2 * ( op(1) == '>' );
    end
    if op(1) == '<',
        z = minus( y, x );
    else
        z = minus( x, y );
    end
    
end

%
% Eliminate lexical redundancies
%

if op( 1 ) == '=',
    cmode = 'full';
else
    cmode = 'magnitude';
end
[ zR, zL ] = bcompress( z, cmode );
if sdp_mode,
    if isreal( zR ),
        nnq = 0.5 * sz( 1 ) * ( sz( 1 ) + 1 );
    else
        nnq = sz( 1 ) * sz( 1 );
    end
    if size( zR, 1 ) > nnq * prod( sz( 3 : end ) ),
        warning( 'CVX:UnsymmetricLMI', [ ...
            'This linear matrix inequality appears to be unsymmetric. This is\n', ...
            'very likely an error that will produce unexpected results. Please check\n', ...
            'the LMI; and, if necessary, re-enter the model.' ], 1 );  
    end
end

%
% Add the (in)equalities
%

touch( prob, zL, op(1) == '=' );
mO = length( cvx___.equalities );
mN = length( zL );
cvx___.equalities = vertcat( cvx___.equalities, zL );
cvx___.needslack( end + 1 : end + mN, : ) = op( 1 ) ~= '=';

%
% Create the dual
%

if ~isempty( dx ),
    zI = cvx_invert_structure( zR )';
    zI = sparse( mO + 1 : mO + mN, 1 : mN, 1 ) * zI;
    zI = cvx( sz, zI );
    duals = builtin( 'subsasgn', duals, dx, zI );
    cvx___.problems( p ).duals = duals;
end

%
% Create the output object
%

if nargout,
    outp = cvxcnst( prob, y_orig );
end

% Copyright 2005-2016 CVX Research, Inc.
% See the file LICENSE.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.
