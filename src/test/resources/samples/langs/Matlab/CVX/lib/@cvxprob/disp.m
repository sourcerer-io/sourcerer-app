function disp( prob, prefix )

if nargin < 2, prefix = ''; end

global cvx___
p = cvx___.problems( prob.index_ );

if isempty( p.variables ),
    nvars = 0;
else
    nvars = length( fieldnames( p.variables ) );
end
if isempty( p.duals ),
    nduls = 0;
else
    nduls = length( fieldnames( p.duals ) );
end
neqns = ( length( cvx___.equalities ) - p.n_equality ) + ...
        ( length( cvx___.linforms )   - p.n_linform  ) + ...
        ( length( cvx___.uniforms )   - p.n_uniform  );
nineqs = nnz( cvx___.needslack( p.n_equality + 1 : end ) ) + ...
         nnz( cvx_vexity( cvx___.linrepls( p.n_linform + 1 : end ) ) ) + ...
         nnz( cvx_vexity( cvx___.unirepls( p.n_uniform + 1 : end ) ) );
neqns = neqns - nineqs;     
if isempty( p.name ) || strcmp( p.name, 'cvx_' ),
    nm = '';
else
    nm = [ p.name, ': ' ];
end

rsv = cvx___.reserved;
nt  = length( rsv );
fv = length( p.t_variable );
qv = fv + 1 : nt;
tt = p.t_variable;
ni = nnz( tt ) - 1;
ndup = sum( rsv ) - nnz( rsv );
neqns = neqns + ndup;
nv = nt - fv + ni + ndup;
tt( qv ) = true;
gfound = nnz( cvx___.logarithm( tt ) );
cfound = false;
for k = 1 : length( cvx___.cones ),
    if any( any( tt( cvx___.cones( k ).indices ) ) ),
        cfound = true;
        break;
    end
end

if all( [ numel( p.objective ), nv, nvars, nduls, neqns, nineqs, cfound, gfound ] == 0 ),
    disp( [ prefix, nm, 'cvx problem object' ] );
else
    if ( p.gp ),
        ptype =' geometric ';
    elseif ( p.sdp ),
        ptype = ' semidefinite ';
    else
        ptype = ' ';
    end
    if isempty( p.objective ),
        tp = 'feasibility';
    else
        switch p.direction,
            case 'minimize',  tp = 'minimization';
            case 'epigraph',  tp = 'epigraph minimization';
            case 'hypograph', tp = 'hypograph maximization';
            case 'maximize',  tp = 'maximization';
        end
        if numel( p.objective ) > 1,
            sz = sprintf( '%dx', size( p.objective ) );
            tp = [ sz(1:end-1), '-objective ', tp ];
        end
    end
    disp( [ prefix, nm, 'cvx', ptype, tp, ' problem' ] );
    if nvars > 0,
        disp( [ prefix, 'variables: ' ] );
        [ vnam, vsiz ] = dispvar( p.variables, '' );
        vnam = strvcat( vnam ); %#ok
        vsiz = strvcat( vsiz ); %#ok
        for k = 1 : size( vnam ),
            disp( [ prefix, '   ', vnam( k, : ), '  ', vsiz( k, : ) ] );
        end
    end
    if nduls > 0,
        disp( [ prefix, 'dual variables: ' ] );
        [ vnam, vsiz ] = dispvar( p.duals, '' );
        vnam = strvcat( vnam ); %#ok
        vsiz = strvcat( vsiz ); %#ok
        for k = 1 : size( vnam ),
            disp( [ prefix, '   ', vnam( k, : ), '  ', vsiz( k, : ) ] );
        end
    end
    if neqns > 0 || nineqs > 0,
        disp( [ prefix, 'linear constraints:' ] );
        if neqns > 0,
            if neqns > 1, plural = 'ies'; else plural = 'y'; end
            fprintf( 1, '%s   %d equalit%s\n', prefix, neqns, plural );
        end
        if nineqs > 0,
            if nineqs > 1, plural = 'ies'; else plural = 'y'; end
            fprintf( 1, '%s   %d inequalit%s\n', prefix, nineqs, plural );
        end
    end
    if cfound || gfound,
        disp( [ prefix, 'nonlinearities:' ] );
        if gfound > 0,
            if gfound > 1, plural = 's'; else plural = ''; end
            fprintf( 1, '%s   %d exponential pair%s\n', prefix, gfound, plural );
        end
        if cfound,
            for k = 1 : length( cvx___.cones ),
                ndxs = cvx___.cones( k ).indices;
                ndxs = ndxs( :, any( reshape( tt( ndxs ), size( ndxs ) ), 1 ) );
                if ~isempty( ndxs ),
                    if isequal( cvx___.cones( k ).type, 'nonnegative' ),
                        ncones = 1;
                        csize = numel(  ndxs  );
                    else
                        [ csize, ncones ] = size( ndxs );
                    end
                    if ncones == 1, plural = ''; else plural = 's'; end
                    fprintf( 1, '%s   %d order-%d %s cone%s\n', prefix, ncones, csize, cvx___.cones( k ).type, plural );
                end
            end
        end
    end
end

function [ names, sizes ] = dispvar( v, name )

switch class( v ),
    case 'struct',
        fn = fieldnames( v );
        if ~isempty( name ), name( end + 1 ) = '.'; end
        names = {}; sizes = {};
        for k = 1 : length( fn ),
            [ name2, size2 ] = dispvar( subsref(v,struct('type','.','subs',fn{k})), [ name, fn{k} ] );
            names( end + 1 : end + length( name2 ) ) = name2;
            sizes( end + 1 : end + length( size2 ) ) = size2;
            if k == 1 && ~isempty( name ), name( 1 : end - 1 ) = ' '; end
        end
    case 'cell',
        names = {}; sizes = {};
        for k = 1 : length( v ),
            [ name2, size2 ] = dispvar( v{k}, sprintf( '%s{%d}', name, k ) );
            names( end + 1 : end + length( name2 ) ) = name2;
            sizes( end + 1 : end + length( size2 ) ) = size2;
            if k == 1, name( 1 : end ) = ' '; end
        end
    case 'double',
        names = { name };
        sizes = { '(constant)' };
    otherwise,
        names = { name };
        sizes = { [ '(', type( v, true ), ')' ] };
end

% Copyright 2005-2016 CVX Research, Inc.
% See the file LICENSE.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.
