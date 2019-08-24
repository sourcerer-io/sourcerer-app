function cvx_optval = sum_square_pos( x, varargin ) %#ok

%SUM_SQUARE_POS   Internal cvx version.

narginchk(1,2);
x2 = [];
cvx_begin
    variable x2( size( x ) );
    minimize( sum_square( x2, varargin{:} ) );
    x2 >= x; %#ok
cvx_end

% Copyright 2005-2016 CVX Research, Inc. 
% See the file LICENSE.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.
