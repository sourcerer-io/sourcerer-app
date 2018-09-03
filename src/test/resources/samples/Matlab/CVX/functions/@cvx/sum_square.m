function cvx_optval = sum_square( x, varargin )

%SUM_SQUARE   Internal cvx version.

narginchk(1,2);
if ~isreal( x ),
    error( 'Disciplined convex programming error:\n   The argument to SUM_SQUARE must be real and affine.', 1 ); %#ok
end
cvx_optval = quad_over_lin( x, 1, varargin{:} );

% Copyright 2005-2016 CVX Research, Inc.
% See the file LICENSE.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.
