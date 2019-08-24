function cvx_optval = det_rootn( X )

%DET_ROOTN nth-root of the determinant of an SPD matrix.
%   For a square matrix X, DET_ROOTN(X) returns
%       POW(DET(X),1/(size(X,1))
%   if X is symmetric (real) or Hermitian (complex) and positive semidefinite,
%   and -Inf otherwise.
%
%   This function can be used in many convex optimization problems that call for
%   LOG(DET(X)) instead. For example, if the objective function contains nothing
%   but LOG(DET(X)), it can be replaced with DET_ROOTN(X), and the same optimal 
%   point will be produced.
%
%   Disciplined convex programming information:
%       DET_ROOTN is concave and nonmonotonic; therefore, when used in
%       CVX specifications, its argument must be affine.

narginchk(1,1);
if ndims( X ) > 2 || size( X, 1 ) ~= size( X, 2 ), %#ok
    error( 'Second argument must be a square matrix.' );
end
err = X - X';
X   = 0.5 * ( X + X' );
if norm( err, 'fro' ) > 8 * eps * norm( X, 'fro' ),
    cvx_optval = -Inf;
else
    [R,p] = chol(X);
    if p > 0,
        cvx_optval = geo_mean(eig(full(X)));
    else
        cvx_optval = geo_mean(diag(R)).^2;
    end
end

% Copyright 2005-2016 CVX Research, Inc. 
% See the file LICENSE.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.
