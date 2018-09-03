function x = touch( p, x, iseq )
global cvx___
if nargin < 3, iseq = false; end

if isa( x, 'cvx' ),
    p  = p.index_;
    b  = cvx_basis( x );
    y  = any( b, 2 );
    if iseq,
    	cvx___.canslack( y ) = false;
    end
    v  = cvx___.problems( p ).t_variable;
    nv = size( v, 1 );
    ny = length( y );
    if ny < nv, 
        y( nv, : ) = 0;
    elseif nv < ny, 
        y = y( 1 : nv, : );
    end
    cvx___.problems( p ).t_variable = v | y;
end

% Copyright 2005-2016 CVX Research, Inc.
% See the file LICENSE.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.
