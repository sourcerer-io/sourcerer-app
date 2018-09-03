function op = linop_dot( A, adj )
%LINOP_DOT  Linear operator formed from a dot product.
%    OP = LINOP_DOT( A ) returns a handle to a TFOCS linear operator 
%    whose forward operation is OP(X) = TFOCS_DOT( A, X ).
%    OP = LINOP_DOT( A, 1 ) returns the adjoint of that operator.

switch class( A ),
    case 'double',
        sz = { size(A), [1,1] };
    case 'cell',
        A = tfocs_tuple(A);
        sz = { tfocs_size(A), [1,1] };
    case 'tfocs_tuple',
        sz = { tfocs_size(A), [1,1] };
    otherwise,
        error( 'First input must be a matrix or cell array of matrices.' );
end
if nargin == 2 && adj,
    sz = { sz{2}, sz{1} };
    op = @(x,mode)linop_dot_adjoint( sz, A, x, mode ); 
else
    op = @(x,mode)linop_dot_forward( sz, A, x, mode ); 
end

function y = linop_dot_forward( sz, A, x, mode )
switch mode,
    case 0, 
        y = sz;
    case 1, 
        y = tfocs_dot( A, x );
    case 2, 
        if ~isreal(x), error( 'Unexpected complex input.' ); end
        y = A * x;
end

function y = linop_dot_adjoint( sz, A, x, mode )
switch mode,
    case 0, 
        y = sz;
    case 1, 
        if ~isreal(x), error( 'Unexpected complex input.' ); end
        y = A * x;
    case 2, 
        y = tfocs_dot( A, x );
end

% TFOCS v1.3 by Stephen Becker, Emmanuel Candes, and Michael Grant.
% Copyright 2013 California Institute of Technology and CVX Research.
% See the file LICENSE for full license information.
