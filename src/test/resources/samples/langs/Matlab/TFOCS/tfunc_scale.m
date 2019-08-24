function op = tfunc_scale( funcF, s, A, b )

%TFUNC_SCALE Scaling a function.
%    SSCALE = TFUNC_SCALE( FUNC, s, A, b ) is the function
%        SSCALE( y ) = s * FUNC( A * y + b ).
%    s must be a real scalar; A can be a scalar, a matrix, or a linear
%    operator; and offset must be a vector of compatible size. The third
%    and fourth arguments are optional; A=I, b=0 are the defaults. If A
%    is a matrix or a linear operator, then the resulting function cannot
%    perform proximity minimizations.
%
%   See also prox_scale

error(nargchk(2,4,nargin));
if ~isa( funcF, 'function_handle' ),
    error( 'The first argument must be a function handle.' );
elseif ~isnumeric( s ) || ~isreal( s ) || numel( s ) ~= 1,
    error( 'The second argument must be a real scalar.' );
end
if nargin < 3,
    A = 1;
elseif ~isnumeric( A ) && ~isa( A, 'function_handle' ),
    error( 'The third argument must be a scalar, matrix, or linear operator.' );
end
if nargin < 4 || isempty( b ),
    b = 0;
elseif ~isnumeric( b ),
    error( 'The fourth argument must be a vector or matrix.' );
end

% Determine the best handle for the job
if s == 0,
    op = smooth_constant( 0 );
elseif ~isnumeric( A ),    
    op = @(varargin)tfunc_scale_linop(  funcF, s, A, b, varargin{:} );
elseif ~nnz(b) || numel( A ) ~= 1,
    op = @(varargin)tfunc_scale_matrix( funcF, s, A, b, varargin{:} );
elseif s ~= 1 || A ~= 1,
    op = @(varargin)tfunc_scale_scalar( funcF, s, A, b, varargin{:} );
else
    op = funcF;
end

function [ v, g ] = tfunc_scale_scalar( funcF, s, a, b, x, t )
switch nargin,
    case 5,
        if nargout == 1,
            v = funcF( a * x + b );
        else
            [ v, g ] = funcF( a * x + b );
            g = ( s * A ) * g;
        end
    case 6,
        [ v, g ] = funcF( a * x + b, s * a * t );
        g = ( g - b ) / a;
    otherwise,
        error( 'Not enough arguments.' );
end
v = s * v;

function [ v, g ] = tfunc_scale_matrix( funcF, s, A, b, x, t )
switch nargin,
    case 5,
        if nargout == 1,
            v = funcF( A * x + b );
        else
            [ v, g ] = funcF( A * x + b );
            g = s * ( A' * g );
        end
    case 6,
        error( 'This function cannot perform proximity minimization.' );
    otherwise,
        error( 'Not enough arguments.' );
end
v = s * v;

function [ v, g ] = tfunc_scale_linop( funcF, s, A, b, x, t )
switch nargin,
    case 5,
        if nargout == 1,
            v = funcF( A( x, 1 ) + b );
        else
            [ v, g ] = funcF( A( x, 1 ) + b );
            g = s * A( g, 2 );
        end
    case 6,
        error( 'This function cannot perform proximity minimization.' );
    otherwise,
        error( 'Not enough arguments.' );
end
v = s * v;

% TFOCS v1.3 by Stephen Becker, Emmanuel Candes, and Michael Grant.
% Copyright 2013 California Institute of Technology and CVX Research.
% See the file LICENSE for full license information.
