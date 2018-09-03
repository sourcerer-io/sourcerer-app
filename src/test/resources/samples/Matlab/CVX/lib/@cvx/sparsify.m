function x = sparsify( x, mode )

global cvx___
narginchk(2,2);
persistent remap

%
% Check mode argument
%

if ~ischar( mode ) || size( mode, 1 ) ~= 1,
    error( 'Second arugment must be a string.' );
end
isobj = strcmp( mode, 'objective' );

pr = cvx___.problems( end );
touch( pr.self, x );
bz = x.basis_ ~= 0;
bs = sum( bz, 1 );
bc = bz( 1, : );
tt = bs > bc + 1;
at = any( tt );
if at,
    
    %
    % Replace posynomials with log-convex monomials --- that is, unless
    % we are taking the exponential of one. (Not that I know why we 
    % would do that!) In that case, we should just use a standard
    % linear replacement and leave it at that.
    %
    
    if ~isequal( mode, 'exponential' ),
        if isempty( remap ),
            remap = cvx_remap( 'posynomial' );
        end
        t2 = remap( cvx_classify( x ) );
        if any( t2 ),
            if all( t2 ),
                x = exp( log( x ) );
            else
                x = cvx_subsasgn( x, t2, exp( log( cvx_subsref( x, t2 ) ) ) );
            end
            bc( t2 ) = 0;
            tt = tt & ~t2;
            at = any( tt );
        end
    end
    
    %
    % Replace other multivariable forms with single-variable forms
    %
    
    if at,
        abc = any( bc( :, tt ) );
        if abc,
            xc = cvx_constant( x );
            x = x - xc;
        end
        forms = cvx___.linforms;
        repls = cvx___.linrepls;
        [ x, forms, repls ] = replcols( x, tt, 'full', forms, repls, isobj );
        cvx___.linforms = forms;
        cvx___.linrepls = repls;
        if abc,
            x = x + xc;
        end
    end
    
end

%
% Arguments: no constraints on coefficients or constant values
% Objectives:     all replaced with coefficient > 0, constant terms preserved
% Exponentiation: coefficient == 1, constant terms perserved
% Logarithm:      coefficient >  0, constant terms eliminated
%

switch mode,
    case { 'argument', 'constraint' },
        tt = false;
    case 'objective',
        tt = ~tt | sum( x.basis_, 1 ) < x.basis_( 1, : );
        usexc = true;
    case 'logarithm',
        tt = sum( x.basis_, 1 ) < x.basis_( 1, : );
        usexc = false;
    case 'exponential';
        tt = sum( x.basis_, 1 ) ~= x.basis_( 1, : ) + 1;
        usexc = true;
    otherwise,
        error( [ 'Invalid normalization mode: ', mode ] );
end
if any( tt ),
    if usexc,
        abc = any( bc );
        if abc,
            xc = cvx_constant( x );
            x = x - xc;
        end
    else
        abc = false;
    end
    forms = cvx___.uniforms;
    repls = cvx___.unirepls;
    [ x, forms, repls ] = replcols( x, tt, 'none', forms, repls, isobj );
    cvx___.uniforms = forms;
    cvx___.unirepls = repls;
    if abc,
        x = x + xc;
    end
end

function [ x, forms, repls ] = replcols( x, tt, mode, forms, repls, isobj )

%
% Sift through the forms, removing duplicates
%

global cvx___
bN = vec( cvx_subsref( x, tt ) );
nO = length( forms );
nN = length( bN );
if nO ~= 0,
    bN = [ forms ; bN ];
end
[ bNR, bN ] = bcompress( bN, mode, nO );
bNR = bNR( :, nO + 1 : end );
nB = length( bN ) - nO;

%
% Create the replacement variables
%

if nB ~= 0,
    forms   = bN;
    bN      = cvx_subsref( bN, nO + 1 : nO + nB, 1 );
    newrepl = newvar( cvx___.problems( end ).self, '', nB );
    [ ndxs, temp ] = find( newrepl.basis_ ); %#ok
    repls = [ repls ; newrepl ];
    bV = cvx_vexity( bN );
    cvx___.vexity( ndxs ) = bV;
    cvx___.readonly( ndxs ) = vec( cvx_readlevel( bN ) );
    if ~isobj,
        ss = bV == 0;
        if any( ss ),
            temp = cvx_basis( bN );
            temp = any( temp( :, ss ), 2 );
            temp( ndxs( ss ) ) = true;
            cvx___.canslack( temp ) = false;
        end
    end
end

%
% Re-expand the structure
%

x = cvx_subsasgn( x, tt, buncompress( bNR, repls, nN ) );

% Copyright 2005-2016 CVX Research, Inc.
% See the file LICENSE.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.
