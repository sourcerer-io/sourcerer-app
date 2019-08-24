function y = cvx_isconstant( x, full )
narginchk(1,2);
b = x.basis_;
if size( b, 1 ) <= 1,
    y = true;
    if nargin == 2 && full,
        y = y( ones( 1, prod( x.size_ ) ) );
        y = reshape( y, x.size_ );
    end
elseif nargin == 2 && full,
    bz = b ~= 0;
    y = cvx_reshape( sum( bz, 1 ) == bz( 1, : ), x.size_ );
else
    y = nnz( b ) == nnz( b( 1, : ) );
end

% Copyright 2005-2016 CVX Research, Inc.
% See the file LICENSE.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.
