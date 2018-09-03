function y = cvxaff( x )
global cvx___
y = subsref( cvx___.problems( x.problem_ ).duals, x.name_ );

% Copyright 2005-2016 CVX Research, Inc. 
% See the file LICENSE.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.
