function op = linop_matrix( A, cmode, width )

%LINOP_MATRIX   Linear operator, assembled from a matrix.
%    If A is a real matrix, OP = LINOP_MATRIX( A ) returns a handle to a
%    TFOCS linear operator that uses that matrix to implement its size, 
%    forward, and adjoint operations.
%
%    If A is a complex matrix, OP = LINOP_MATRIX( A, MODE ) returns a
%    handle to a TFOCS linear operator that uses A to implement its size,
%    forward, and linear operator. MODE is a string that tells it how to
%    handle its complex inputs/outputs:
%          'R2R': real input, real output (real matrices only)
%          'R2C': real input, complex output
%          'C2R': complex input, real output
%          'C2C': complex input, complex output 
%    If the operator detects complex input when it is not expecting it, it
%    will issue an error.
%
%    OP = LINOP_MATRIX( A, MODE, WIDTH )
%       further specifies that A operates on matrices with WIDTH number
%       of columns (and output also has WIDTH columns).  Default is 1.
%
%    Typically, end users do not need to call this routine. You may supply
%    matrices directly to TFOCS, and it will call this as needed.

if ~isnumeric( A ) || ndims( A ) > 2,
    error( 'First input must be a matrix.' );
end
if nargin < 3, width = 1; end
if numel( A ) == 1,
    sz = { [], [] };
else
    sz = { [ size(A,2), width ], [ size(A,1), width ] };
end
if nargin < 2 || isempty( cmode ),
    if ~isreal( A ),
        error( 'A real/complex mode must be supplied for complex matrices.' );
    end
    cmode = 'R2R';
elseif ~ischar( cmode ) || size( cmode, 1 ) ~= 1,
    error( 'Complex mode must be a string.' );
else
    cmode = upper(cmode);
end
switch cmode,
    case 'R2R',
        if ~isreal( A ),
            error( 'An "R2R" operator requires a real matrix.' );
        end
        op = @(x,mode)linop_matrix_r2r( sz, A, x, mode );
    case 'R2C', op = @(x,mode)linop_matrix_r2c( sz, A, x, mode );
    case 'C2R', op = @(x,mode)linop_matrix_c2r( sz, A, x, mode );
    case 'C2C', op = @(x,mode)linop_matrix_c2c( sz, A, x, mode );
    otherwise,
        error( 'Unexpected complex mode string: %s', op );
end

function y = linop_matrix_r2r( sz, A, x, mode )
switch mode,
    case 0, y = sz;
    case 1, y = A  * realcheck( x );
    case 2, y = A' * realcheck( x );
end

function y = linop_matrix_r2c( sz, A, x, mode )
switch mode,
    case 0, y = sz;
    case 1, y = A * realcheck( x );
    case 2, y = real( A' * x );
end

function y = linop_matrix_c2r( sz, A, x, mode )
switch mode,
    case 0, y = sz;
    case 1, y = real( A * x );
    case 2, y = A' * realcheck( x );
end

function y = linop_matrix_c2c( sz, A, x, mode )
switch mode,
    case 0, y = sz;
    case 1, y = A * x;
    case 2, y = A' * x;
end

function y = realcheck( y )
if ~isreal( y ), 
    error( 'Unexpected complex value in linear operation.' );
end

% TFOCS v1.3 by Stephen Becker, Emmanuel Candes, and Michael Grant.
% Copyright 2013 California Institute of Technology and CVX Research.
% See the file LICENSE for full license information.
