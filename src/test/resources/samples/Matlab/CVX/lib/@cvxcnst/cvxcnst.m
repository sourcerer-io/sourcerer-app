function v = cvxcnst( p, rhs )
v = class( struct( 'problem', p, 'rhs', rhs ), 'cvxcnst' );

% Copyright 2005-2016 CVX Research, Inc.
% See the file LICENSE.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.
