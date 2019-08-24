function cvx_optval = log_det( X )

%LOG_DET   Logarithm of the determinant of an SDP matrix.
%   For a square matrix X, LOG_DET(X) returns
%       LOG(DET(X))
%   if X is symmetric (real) or Hermitian (complex) and positive semidefinite,
%   and -Inf otherwise.
%
%   When used in a CVX model, LOG_DET(X) causes CVX's successive 
%   approximation method to be invoked, producing results exact to within
%   the tolerance of the solver. Therefore, whenever possible, the use of
%   DET_ROOTN(X) is to be preferred, because the latter choice can be
%   represented exactly in an SDP. For example, the objective
%       MAXIMIZE(LOG_DET(X))
%   can be (and should be) replaced with
%       MAXIMIZE(DET_ROOTN(X))
%   in fact, LOG_DET(X) is implemented simply as N*LOG(DET_ROOTN(X)).
%
%   Disciplined convex programming information:
%       LOG_DET is concave and nonmonotonic; therefore, when used in
%       CVX specifications, its argument must be affine.

narginchk(1,1);
cvx_expert_check( 'log_det', X );
if ndims( X ) > 2 || size( X, 1 ) ~= size( X, 2 ), %#ok
    error( 'Argument must be a square matrix.' );
end
cvx_optval = size(X,1)*log(det_rootn(X));

% Copyright 2005-2016 CVX Research, Inc. 
% See the file LICENSE.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.
