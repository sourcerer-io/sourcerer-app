function [ y, symm ] = cvx_s_sparse( m, n, symm, i, j )

%CVX_S_SPARSE Matrices with a fixed sparsity pattern.

if nargin < 5,
    error( 'Sparsity structure missing.' );
elseif ~isnumeric( i ) || ~isnumeric( j ),
    error( 'Sparsity arguments must be vectors of nonnegative integers.' );
elseif any( i <= 0 ) || any( j <= 0 ) || any( i ~= floor( i ) ) || any( j ~= floor( j ) ),
    error( 'Sparsity arguments must be vectors nonnegative integers.' );
elseif numel( i ) ~= 1 && numel( j ) ~= 1 && numel( i ) ~= numel( j ),
    error( 'Sparsity arguments have incompatible size.' );
elseif any( i > m ) || any( j > n ),
    error( 'One or more indices are out of range.' );
elseif symm && m ~= n,
    error( 'Symmetric structure requires a square matrix.' );
end
i = i(:); 
j = j(:);
nz = max( numel(i), numel(j) );
if symm,
    t = max(i,j);
    j = min(i,j);
    i = t;
end
[ c, cndxs ] = sort( i + ( j - 1 ) * m );
tt = [true;c(2:end)~=c(1:end-1)];
c = c(tt);
r = 1 : length(c);
if symm,
    if numel(i) > 1,
        i = i(cndxs(tt));
    end
    if numel(j) > 1,
        j = j(cndxs(tt));
    end
    tt = i ~= j;
    r = [ r , r(tt) ];
    c = [ c ; j(tt) + ( i(tt) - 1 ) * m ];
end
y = min( sparse( r, c, 1, nz, m * n ), 1 );
symm = false;

% Copyright 2005-2016 CVX Research, Inc. 
% See the file LICENSE.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.
