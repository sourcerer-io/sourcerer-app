function z = sigma_max( x )

%SIGMA_MAX    Maximum singular value.
%   SIGMA_MAX(X) returns the maximum singular value of X. X must be a 2-D
%   matrix, real or complex. SIGMA_MAX(X) is synonymous with NORM(X).
%
%   Disciplined convex programming information:
%       SIGMA_MAX(X) is convex and nonmontonic in X, so X must be affine.

narginchk(1,1);
z = norm( x, 2 );

% Copyright 2005-2016 CVX Research, Inc. 
% See the file LICENSE.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.
