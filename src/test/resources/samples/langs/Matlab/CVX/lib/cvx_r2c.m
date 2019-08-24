function x = cvx_r2c( x, dim )

%
% Quick exit for complex quantities
%

if ~isreal( x ),
    error( 'Matrix must be real.' );
end

%
% Determine expansion dimension
%

sx = size( x );
if nargin < 2,
    dim = [ find( sx > 1 ), 1 ];
    dim = dim( 1 );
elseif ~isnumeric( dim ) || dim <= 0 || dim ~= floor( dim ),
    error( 'Second argument must be a dimension.' );
end
nd = length( sx );
if nd < dim || rem( sx( dim ), 2 ) ~= 0,
    error( 'The size of the array along the key dimension must be even.' );
end

%
% Extract the real and imaginary halves
%

[ ndxs{ 1 : nd } ] = deal( ':' );
ndxs{ dim } = 1 : 2 : sx( dim );
xr = cvx_subsref( x, ndxs{:} );
ndxs{ dim } = 2 : 2 : sx( dim );
xi = cvx_subsref( x, ndxs{:} );

%
% Combine
%

x = xr + 1i * xi;

% Copyright 2005-2016 CVX Research, Inc.
% See the file LICENSE.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.
