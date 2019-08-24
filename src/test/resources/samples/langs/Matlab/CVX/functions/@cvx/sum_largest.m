function cvx_optval = sum_largest( x, k, dim )

%SUM_LARGEST   Internal cvx version.

narginchk(2,3);
sx = size( x );
if nargin < 3 || isempty( dim ),
	dim = cvx_default_dimension( sx );
elseif ~cvx_check_dimension( dim ),
    error( 'Second argument must be a dimension.' );
elseif ~isnumeric( k ) || ~isreal( k ),
    error( 'Third argument must be a real scalar.' );
elseif ~isreal( x ),
    error( 'First argument must be real.' );
end

%
% Quick exit cases
%

sx( end + 1 : dim ) = 1;
sy = sx;
sy( dim ) = 1;
if k <= 0,

    cvx_optval = zeros( sy );

elseif k <= 1,

    cvx_optval = k * max( x, [], dim );

elseif k >= sx( dim ),

    cvx_optval = sum( x, dim );

else

	z = []; xp = []; yp = [];
    cvx_begin
        epigraph variable z( sy )
        variables xp( sx ) yp( sy )
        z == sum( xp, dim ) - k * yp; %#ok
        xp >= cvx_expand_dim( yp, dim, sx(dim) ) + x; %#ok
        xp >= 0; %#ok
    cvx_end

end

% Copyright 2005-2016 CVX Research, Inc.
% See the file LICENSE.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.
