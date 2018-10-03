function cvx_optval = norm( x, p )

%   Disciplined convex programming information:
%       NORM is convex, except when P<1, so an error will result if
%       these non-convex "norms" are used within CVX expressions. NORM 
%       is nonmonotonic, so its input must be affine.

%
% Argument map
%

persistent remap1 remap2
if isempty( remap2 ),
    remap1 = cvx_remap( 'log-convex' );
    remap2 = cvx_remap( 'affine', 'log-convex' );
end

%
% Check arguments
%

narginchk(1,2);
if nargin < 2,
    p = 2;
elseif ~isequal( p, 'fro' ) && ( ~isnumeric( p ) || ~isreal( p ) || p < 1 ),
    error( 'Second argument must be a real number between 1 and Inf, or ''fro''.' );
end
if ndims( x ) > 2, %#ok
    error( 'norm is not defined for N-D arrays.' );
end

[m,n] = size(x);
if m == 1 || n == 1 || isequal( p, 'fro' ),
    
    %
    % Vector norms
    %
    
    if isempty( x ),
        cvx_optval = cvx( 0 );
        return
    end
    if isequal( p, 'fro' ),
        p = 2;
    end
    x = svec( x, p );
    if length( x ) == 1,
        p = 1;
    end
    xc = cvx_classify( x );
    if ~all( remap2( xc ) ),
        error( 'Disciplined convex programming error:\n    Cannot perform the operation norm( {%s}, %g )', cvx_class( x ), p );
    end
    switch p,
        case 1,
            cvx_optval = sum( abs( x ) );
        case Inf,
            cvx_optval = max( abs( x ) );
        otherwise,
            tt = remap1( xc );
            if all( tt ),
                cvx_optval = ( sum( x .^ p ) ) .^ (1/p);
            else
                if nnz( tt ) > 1,
                    tt = tt ~= 0;
                    xx = cvx_subsref( x, tt );
                    xx = ( sum( xx .^ p ) ) .^ (1/p);
                    x  = [ cvx_subsref( x, ~tt ) ; cvx_accept_convex( xx ) ];
                end
                n = length( x );
                if p == 2,
                    z = [];
                    cvx_begin
                        epigraph variable z
                        { x, z } == lorentz( n, [], ~isreal( x ) ); %#ok
                    cvx_end
                else
                    if isreal( x ),
                        cmode = 'abs';
                    else
                        cmode = 'cabs';
                    end
                    y = []; z = [];
                    cvx_begin
                        epigraph variable z
                        variable y( n )
                        { [ y, z*ones(n,1) ], x } == geo_mean_cone( [n,2], 2, [1/p,1-1/p], cmode ); %#ok
                        sum( y ) == z; %#ok
                    cvx_end
                end
            end
    end
    
else
    
    %
    % Matrix norms
    %
    
    if ~cvx_isaffine( x ),
        error( 'Disciplined convex programming error:\n    Cannot perform the operation norm( {%s}, %g )\n   when the first argument is a matrix.', cvx_class( xt ), p );
    end
    switch p,
        case 1,
            cvx_optval = max( sum( abs( x ), 1 ), [], 2 );
        case Inf,
            cvx_optval = max( sum( abs( x ), 2 ), [], 1 );
        case 2,
            cvx_optval = sigma_max( x );
        otherwise,
            error( 'The only matrix norms available are 1, 2, Inf, and ''fro''.' );
    end
    
end

% Copyright 2005-2016 CVX Research, Inc.
% See the file LICENSE.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.
