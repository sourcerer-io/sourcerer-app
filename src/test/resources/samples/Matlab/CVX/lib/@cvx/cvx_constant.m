function y = cvx_constant( x )
y = cvx_reshape( x.basis_( 1, : ), x.size_ );

% Copyright 2005-2016 CVX Research, Inc.
% See the file LICENSE.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.
