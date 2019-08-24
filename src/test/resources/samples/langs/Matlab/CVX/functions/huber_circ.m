function y = huber_circ( x, DIM, varargin )

%HUBER_CIRC   Huber penalty function with circular symmetry.
%   For a vector X, HUBER_CIRC(X) computes the Huber penalty function
%
%       HUBER_CIRC(X) =   NORM(X,2)^2 if NORM(X,2)<=1,
%                       2*NORM(X,2)-1 if NORM(X,2)>=1.
%
%   For matrices and N-D arrays, the penalty function is applied to the
%   first dimens
%
%   HUBER_CIRC(X,[],M) computes the penalty function with halfwidth M,
%   M.^2.*HUBER_CIRC(X./M). M must be real and positive.
%
%   HUBER_CIRC(X,[],M,T) computes the penalty function with halfwidth M
%   and concomitant scale T:
%
%       HUBER_CIRC(X,[],M,T) = T.*HUBER_CIRC(X./T,[],M) if T > 0
%                              +Inf                     if T <= 0
%
%   See the help file for HUBER for information about this usage.
%
%   If X is a matrix, the penalty function is applied to the columns of the
%   matrix X, and a row vector is returned. If X is an N-D matrix, the 
%   penalties are computed along the first non-singleton dimension.
%
%   HUBER_CIRC(X,DIM), HUBER_CIRC(X,DIM,M), and HUBER_CIRC(X,DIM,M,T) 
%   computes the penalty along the dimension DIM.
%
%   Disciplined convex programming information:
%       HUBER_CIRC is jointly convex in X and T. It is nonomonotonic in X 
%       and nonincreasing in T. Therefore, when used in CVX specifications, 
%       X must be affine and T must be concave (or affine). T must be real.
%       X, on the other hand, may be real or complex.

if ~cvx_isaffine( x ),
    error( 'Disciplined convex programming error:\n    HUBER_CIRC is nonmonotonic in X, so X must be affine.', 1 ); %#ok
end
if nargin < 2, DIM = []; end
y = huber_pos( norms( x, DIM ), varargin{:} );

% Copyright 2005-2016 CVX Research, Inc. 
% See the file LICENSE.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.
