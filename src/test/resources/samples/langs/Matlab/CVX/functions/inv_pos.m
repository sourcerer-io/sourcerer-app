function y = inv_pos( x )

%INV_POS   Reciprocal of a positive quantity.
%    INV_POS(X) returns 1./X if X is positive, and +Inf otherwise.
%    X must be real.
%
%    For matrices and N-D arrays, the function is applied to each element.
%
%     Disciplined convex programming information:
%         INV_POS is convex and nonincreasing; therefore, when used in CVX
%         specifications, its argument must be concave (or affine).

narginchk(1,1);
if ~isreal( x ),
    error( 'Input must be real.' );
end
y = 1.0 ./ max( x, 0 );

% Copyright 2005-2016 CVX Research, Inc.
% See the file LICENSE.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.
