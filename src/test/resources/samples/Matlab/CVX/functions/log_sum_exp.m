function y = log_sum_exp( x, dim )

%LOG_SUM_EXP    log(sum(exp(x))).
%   LOG_SUM_EXP(X) = LOG(SUM(EXP(X)).
%
%   When used in a CVX model, LOG_SUM_EXP(X) causes CVX's successive
%   approximation method to be invoked, producing results exact to within
%   the tolerance of the solver. This is in contrast to LOGSUMEXP_SDP,
%   which uses a single SDP-representable global approximation.
%
%   If X is a matrix, LOGSUMEXP_SDP(X) will perform its computations
%   along each column of X. If X is an N-D array, LOGSUMEXP_SDP(X)
%   will perform its computations along the first dimension of size
%   other than 1. LOGSUMEXP_SDP(X,DIM) will perform its computations
%   along dimension DIM.
%
%   Disciplined convex programming information:
%       LOG_SUM_EXP(X) is convex and nondecreasing in X; therefore, X
%       must be convex (or affine).

narginchk(1,2);
if ~isreal( x ),
    error( 'Argument must be real.' );
end
y = exp( x );
if nargin == 1,
    y = sum( y );
else
    y = sum( y, dim );
end
y = log( y );

% Copyright 2005-2016 CVX Research, Inc. 
% See the file LICENSE.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.
