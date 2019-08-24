function cvx_optval = square_abs( x )

%SQUARE_ABS   Internal cvx version.

narginchk(1,1);
cvx_optval = pow_abs( x, 2 );

% Copyright 2005-2016 CVX Research, Inc. 
% See the file LICENSE.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.
