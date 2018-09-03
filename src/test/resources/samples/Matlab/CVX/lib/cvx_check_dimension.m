function y = cvx_check_dimension( x, zero_ok )

%CVX_CHECK_DIMENSION   Verifies that the input is valid dimension.
%   CVX_CHECK_DIMENSION( DIM ) verifies that the quantity DIM is valid for use
%   in commands that call for a dimension; e.g., SUM( X, DIM ). In other words,
%   it verifies that DIM is a positive integer scalar.
%
%   CVX_CHECK_DIMENSION( DIM, ZERO_OK ) allows DIM to be zero if ZERO_OK is
%   true. If ZERO_OK is false, the default behavior is used.

if isnumeric( x ) && length( x ) == 1 && isreal( x ) && x < Inf && x == floor( x ),
    if nargin < 2, zero_ok = false; end
    y = x > 0 | zero_ok;
else
    y = 0;
end

% Copyright 2005-2016 CVX Research, Inc.
% See the file LICENSE.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.
