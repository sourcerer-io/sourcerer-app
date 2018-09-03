function y = cvx_isconcave( x, full )
narginchk(1,2);
y = cvx_vexity( x );
if nargin < 2,
    y = nnz( y > 0 ) == 0;
else
    y = cvx_reshape( y <= 0, x.size_ );
end

% Copyright 2005-2016 CVX Research, Inc.
% See the file LICENSE.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.
