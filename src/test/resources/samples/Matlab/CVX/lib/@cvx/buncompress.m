function x = buncompress( xR, x, sx )
narginchk(2,3);

if ~isa( xR, 'double' ) && ~isa( xR, 'sparse' ),
    error( 'First argument must be a structure matrix.' );
elseif size( x.basis_, 2 ) ~= size( xR, 1 ),
    error( 'Structure matrix incompatible with vector.' );
elseif nargin < 3 || isempty( sx ),
    sx = size( xR, 2 );
elseif ~cvx_check_dimlist( sx, false ),
    error( 'Third argument must be a size matrix.' );
elseif prod( sx ) ~= isempty( xR ) * prod( x.size_ ) + ~isempty( xR ) * size( xR, 2 ),
    error( 'Incompatible size matrix.' );
end

if isempty( xR ),
    x = cvx( sx, x.basis_ );
else
    x = cvx( sx, x.basis_ * xR );
end

% Copyright 2005-2016 CVX Research, Inc.
% See the file LICENSE.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.
