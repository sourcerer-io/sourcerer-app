function y = cvxobj()
global cvx___
if isempty( cvx___ ),
    error( 'Internal cvx data corruption' );
end
cvx___.id = cvx___.id + 1;
y = class( struct( 'id_', cvx___.id ), 'cvxobj' );

% Copyright 2005-2016 CVX Research, Inc.
% See the file LICENSE.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.
