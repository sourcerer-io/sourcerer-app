function a = le( x, y )

b = newcnstr( evalin( 'caller', 'cvx_problem', '[]' ), x, y, '<=' );
if nargout, a = b; end

% Copyright 2005-2016 CVX Research, Inc.
% See the file LICENSE.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.
