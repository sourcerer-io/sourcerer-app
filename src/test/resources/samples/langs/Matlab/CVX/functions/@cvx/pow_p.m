function y = pow_p( x, p )

%POW_P   Internal cvx version.

narginchk(2,2);
y = pow_cvx( x, p, 'pow_p' );

% Copyright 2005-2016 CVX Research, Inc.
% See the file LICENSE.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.
