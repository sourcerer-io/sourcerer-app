function cvx_optval = det_root2n( X )

%DET_ROOT2N 2nth-root of the determinant of an SPD matrix.
%     For a square matrix X, DET_ROOT2N(X) returns
%         POW(DET(X),1/(2*size(X,1))
%     if X is symmetric (real) or Hermitian (complex) and positive
%     semidefinite, and -Inf otherwise.
%
%     This function has been replaced in significance with DET_ROOTN(X),
%     and is now simply implemented as SQRT(DET_ROOTN(X)). Please see
%     DET_ROOTN for more information on its usefulness.
%
%     Disciplined convex programming information:
%         DET_ROOT2N is concave and nonmonotonic; therefore, when used in
%         CVX specifications, its argument must be affine.

narginchk(1,1);
cvx_optval = sqrt(det_rootn(X));

% Copyright 2005-2016 CVX Research, Inc.
% See the file LICENSE.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.
