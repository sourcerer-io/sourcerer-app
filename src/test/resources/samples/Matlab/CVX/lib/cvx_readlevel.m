function y = cvx_readlevel( x )
if ndims( x ) <= 2,
    y = sparse( size( x, 1 ), size( x, 2 ) );
else
    y = zeros( size( x ) );
end

% Copyright 2005-2016 CVX Research, Inc.
% See the file LICENSE.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.
