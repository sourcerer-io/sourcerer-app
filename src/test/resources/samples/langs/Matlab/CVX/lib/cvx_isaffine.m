function y = cvx_isaffine( x, full ) %#ok
narginchk(1,2);
if nargin == 1,
    y = true;
else
    y = true( size( x ) );
end

% Copyright 2005-2016 CVX Research, Inc.
% See the file LICENSE.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.
