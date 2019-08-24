function x = cvx_zeros( s )
if cvx_use_sparse( s, 0, 1 ),
     x = sparse( s(1), s(2) );
else
     x = zeros( s );
end

% Copyright 2005-2016 CVX Research, Inc.
% See the file LICENSE.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.
