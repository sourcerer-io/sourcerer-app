function [ y, symm ] = cvx_s_symmetric_ut( m, n, symm )
%CVX_S_SYMMETRIC_UT Symmetric matrices (upper triangle storage).
if m ~= n,
    error( 'Symmetric structure requires square matrices.' );
end
symm = false;
nsq = n * n;
ntr = 0.5 * ( nsq + n );
c   = 0 : n - 1;
c   = c( ones( 1, n ), : );
r   = c';
mn  = min( r, c );
mx  = max( r, c );
y   = mn + 0.5 * mx .* ( mx + 1 ) + 1;
y   = sparse( y( : ), 1 : nsq, 1, ntr, nsq );

% Copyright 2005-2016 CVX Research, Inc. 
% See the file LICENSE.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.
