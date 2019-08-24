function v = cvx_value( x )
warning( 'CVX:IllegalUse', ...
    'CVX error: illegal use of a cvx problem object has been detected.\n   Please do not copy or manipulate the value of ''cvx_problem'' in any way.', 1 ); %#ok
v = [];

% Copyright 2005-2016 CVX Research, Inc.
% See the file LICENSE.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.
