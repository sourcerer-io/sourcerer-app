function y = cvx_isnonzero( x, full )
narginchk(1,2);
y = any( x.basis_, 1 );
if nargin < 2,
    y = all( y );
else
    y = cvx_reshape( y, x.size_ );
end

% Copyright 2005-2016 CVX Research, Inc.
% See the file LICENSE.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.
