function y = cvx_vexity( x )
sx = size( x );
if cvx_use_sparse( sx, 0, true )
    y = sparse( sx(1), sx(2) );
else
    y = zeros( sx );
end

% Copyright 2005-2016 CVX Research, Inc.
% See the file LICENSE.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.
