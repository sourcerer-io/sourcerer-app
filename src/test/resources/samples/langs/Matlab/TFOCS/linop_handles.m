function op = linop_handles( sz, Af, At, cmode )
%LINOP_HANDLES Linear operator from user-supplied function handles.
%OP = LINOP_HANDLES( SZ, AF, AT, CMODE )
%    Constructs a TFOCS-compatible linear operator from separate function
%    handles that compute the forward and adjoint operations. The first
%    argument, SZ, gives the size of the linear operator; and the forward
%    and adjoint handles are AF and AT, respectively.
% 
%    If the inputs and outputs are simple vectors, then SZ can take the
%    standard Matlab form [M,N], where N is the input length and M is the
%    output length. If the input or output is a matrix or array, then SZ
%    should take the form { S_in, S_out }, where S_in is the size of the
%    input and S_out is the size of the output.
%
%    If the input or output space of the operator is complex, then the
%    CMODE string must be supplied, which describes the forward operation:
%       'R2R': real input and output
%       'R2C': real input, complex output
%       'C2R': complex input, real output
%       'C2C': complex input, complex output
%    If CMODE is not supplied, then 'R2R' is assumed. If the operator
%    detects a complex input or output when it is not expected, then an
%    error results. Therefore, you must make sure that your operators 
%    return real values when they are expected to do so.

error(nargchk(3,4,nargin));
if numel( sz ) ~= 2,
    error( 'Size must have two elements.' );
elseif isnumeric( sz ),
    sz = { [sz(2),1], [sz(1),1] };
elseif ~isa( sz, 'cell' ),
    error( 'Invalid operator size specification.' );
end
if ~isa( Af, 'function_handle' ) || ~isa( At, 'function_handle' ),
    error( 'Second and third arguments must be function handles.' );
end
if nargin < 4 || isempty( cmode ),
    cmode = 'R2R';
elseif ~ischar( cmode ) || size( cmode, 1 ) ~= 1,
    error( 'Fourth argument must be a string.' );
else
    cmode = upper( cmode );
end

switch cmode,
    case 'R2R', op = @(x,mode)linop_handles_r2r( sz, Af, At, x, mode );
    case {'R2C','R2CC'}, op = @(x,mode)linop_handles_r2c( sz, Af, At, x, mode );
    case {'C2R','CC2R'}, op = @(x,mode)linop_handles_c2r( sz, Af, At, x, mode );
    case 'C2C', op = @(x,mode)linop_handles_c2c( sz, Af, At, x, mode );
    otherwise,
        error( 'Invalid complex mode: %s', cmode );
end

function y = linop_handles_r2r(sz, Af, At, x, mode )
switch mode,
    case 0, y = sz;
    case 1, y = realcheck( Af( realcheck( x ) ) );
    case 2, y = realcheck( At( realcheck( x ) ) );
end

function y = linop_handles_r2c(sz, Af, At, x, mode )
switch mode,
    case 0, y = sz;
    case 1, y = Af( realcheck( x ) );
    case 2, y = realcheck( At( x ) );
end

function y = linop_handles_c2r(sz, Af, At, x, mode )
switch mode,
    case 0, y = sz;
    case 1, y = realcheck( Af( x ) );
    case 2, y = At( realcheck( x ) );
end

function y = linop_handles_c2c(sz, Af, At, x, mode )
switch mode,
    case 0, y = sz;
    case 1, y = Af( x );
    case 2, y = At( x );
end

function y = realcheck( y )
if ~isreal( y ), 
    error( 'Unexpected complex value in linear operation.' );
end

% TFOCS v1.3 by Stephen Becker, Emmanuel Candes, and Michael Grant.
% Copyright 2013 California Institute of Technology and CVX Research.
% See the file LICENSE for full license information.
