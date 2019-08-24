function t = toeplitz( c, r )

%   Disciplined convex/geometric programming information for TOEPLITZ:
%      TOEPLITZ imposes no convexity restrictions on its arguments. 
%      Instead of using the TOEPLITZ function, however, consider 
%      creating a matrix variable using the 'toeplitz' keyword; e.g.
%          variable X(5,5) toeplitz;

%
% Check arguments
%

narginchk(1,2);
if nargin < 2,
    c    = vec( c );
    m    = length( c );
    p    = m;
    x    = [ cvx_subsref( c, p : -1 : 1 ) ; conj( cvx_subsref( c, 2 : p ) ) ];
else
    temp = cvx_subsref( r, 1 ) - cvx_subsref( c, 1 );
    if ~cvx_isconstant( temp ) || cvx_constant( temp ) ~= 0,
        warning('MATLAB:toeplitz:DiagonalConflict',['First element of ' ...
               'input column does not match first element of input row. ' ...
               '\n         Column wins diagonal conflict.'])
    end
    r = vec( r );
    c = vec( c );
    p = length( r );
    m = length( c );
    x = [ cvx_subsref( r, p : -1 : 2 ) ; c ];
end

%
% Construct matrix
%

cidx = ( 0 : m - 1 )';
ridx = p : -1 : 1;
t    = cidx( :, ones( p, 1 ) ) + ridx( ones( m, 1 ) , : );
t    = reshape( cvx_subsref( x, t ), size( t ) );

% Copyright 2005-2016 CVX Research, Inc.
% See the file LICENSE.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.
