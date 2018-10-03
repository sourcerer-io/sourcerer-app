function [ xR, x ] = cvx_bcompress( x, mode, num_sorted )
narginchk(1,3);
if nargin < 3 || isempty( num_sorted ),
    num_sorted = 0;
end
if nargin < 2 || isempty( mode ),
    mode = 0;
else
    switch mode,
        case 'full',      mode = 0;
        case 'magnitude', mode = 1;
        case 'none',      mode = 2;
        otherwise,        error( [ 'Invalid normalization mode: ', mode ] );
    end
end

%
% Separate the real and imaginary parts. But while we're at it, we need to
% make sure we we're at it, 
%

[ m, n ] = size( x ); %#ok
iscplx = ~isreal( x );
if iscplx,
    x = cvx_c2r( x, 2, 8 * eps );
    n = n * 2;
end

[ ndxs, scls ] = cvx_bcompress_mex( sparse( x ), mode, num_sorted );
xR = sparse( ndxs, 1 : n, scls, n, n );
t2 = any( xR, 2 );
xR = xR( t2, : );

if nargout > 1 && ~all( t2 ),
    x = x( :, t2 );
end

if iscplx,
    xR = cvx_r2c( xR, 2 );
end

% Copyright 2005-2016 CVX Research, Inc.
% See the file LICENSE.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.
