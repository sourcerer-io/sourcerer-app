function y = log_normcdf( x )

%LOG_NORMCDF   Internal CVX version.

narginchk(1,1);
if ~isreal( x ),
    error( 'Argument must be real.' );
end

persistent a b nb ob
if isempty( a ),
    a =sqrt( [ 0.018102332171520
               0.011338501342044
               0.072727608432177
               0.184816581789135
               0.189354610912339
               0.023660365352785 ] );
    a = sparse(diag(a));
    b = [3 2.5 2 1 -1 -2]';
    nb = length(b);
    ob = ones(nb,1);
end

cx = cvx_isconstant( x );
sx = size(x);
nx = prod(sx);
y  = a * ( b * ones(1,nx) - ob * reshape( x, 1, nx ) );
if cx,
    y = cvx( sum( cvx_constant( max( y, 0 ) ) .^ 2 ) );
else
    y = sum_square_pos( y );
end
y = - reshape( y, sx );

% Copyright 2005-2016 CVX Research, Inc. 
% See the file LICENSE.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.
