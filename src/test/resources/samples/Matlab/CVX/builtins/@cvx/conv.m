function z = conv(x,y)

%Disciplined convex programming information for CONV:
%   Convolutions are a combination of both multiplications and additions.
%   Therefore, to insure that the no-product rule is satisfied, CONV(X,Y)
%   requires that either X or Y be constant. Further conditions may also
%   apply depending on the exact content of X and Y. For example, if the
%   elements of Y are all convex, then the convolution kernel X must be
%   real, and all of the elements must have the same sign.
%
%Disciplined geometric programming information for TIMES:
%   CONV(X,Y) requires that either X or Y be constant, and that the
%   non-constant term be log-convex or log-affine. Strictly speaking,
%   CONV(X,Y) where X and Y are both log-convex satisfies the DGP rulest,
%   but this version does not support that scenario.

narginchk(2,2);
sx = size(x);
sy = size(y);
if sum(sx~=1)>1 || sum(sy~=1)>1,
    
    error( 'Arguments must be vectors.' );
    
elseif any(sx==0) && any(sy==0),
    
    error( 'At least one argument must be non-empty.' );
    
elseif cvx_isconstant(x) || cvx_isconstant(y),    
    
    sz = sy;
    sx = prod(sx);
    sy = prod(sy);
    nz = sx + sy - 1;
    sz(sz>1) = nz;
    if cvx_isconstant(x),
        [xi,xj,xv] = find(cvx_constant(x));
        yb         = cvx_basis(y);
    else
        [xi,xj,xv] = find(cvx_constant(y));
        yb         = cvx_basis(x);
    end
    [yi,yj,yv] = find(yb);
    nx = length(xv);
    ny = length(yv);
    ox = ones(1,nx);
    yi = yi(:,ox);
    xi = reshape( xi + xj - 2, 1, nx ); 
    yj = yj(:,ox) + xi(ones(ny,1),:);
    yv = yv * reshape( xv, 1, nx );
    z  = sparse( yi, yj, yv, size(yb,1), nz );
    z  = cvx( sz, z );
    if nnz( cvx_classify( z ) == 13 ),
        error( 'Disciplined convex programming error:\n   Illegal affine combination of convex/concave terms in convolution.' );
    end
    
else
    
    error( 'At least one argument must be constant.' );
    
end

% Copyright 2005-2016 CVX Research, Inc.
% See the file LICENSE.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.
