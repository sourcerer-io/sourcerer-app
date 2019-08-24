function z = norm_nuc( x )

%NORM_NUC   Nuclear norm of a matrix.
%   NORM_NUC(X) = SUM(SVD(X)). X must be a 2-D matrix, real or complex.
%
%   Disciplined convex programming information:
%       NORM_NUC(X) is convex and nonmontonic in X, so X must be affine.

narginchk(1,1);
z = sum(svd(x));

% Copyright 2005-2016 CVX Research, Inc. 
% See the file LICENSE.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.
