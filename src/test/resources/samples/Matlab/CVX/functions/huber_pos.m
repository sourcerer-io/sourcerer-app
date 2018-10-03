function y = huber_pos( x, M, t )

%HUBER_POS   Monotonic huber penalty function.
%   For a vector X, HUBER_POS(X) computes the monotonic Huber-style function
% 
%                      0     if 0>=X
%       HUBER_POS(X) = X^2   if 0<=X<=1
%                      2*X-1 if    X>=1
%
%   HUBER_POS(X,M) is the monotonic Huber-style penalty function of
%   halfwidth M, M.^2.*HUBER_POS(X./M). M must be real and positive.
%
%   HUBER_POS(X,M,T) computes the monotonic Huber-style penalty function 
%   with halfwidth M and concomitant scale T:
%
%       HUBER_POS(X,M,T) = T.*HUBER_POS(X./T,M) if T > 0
%                          +Inf                 if T <= 0
%
%   See the help file for HUBER for information about this usage.
%
%   For matrices and N-D arrays, the penalty function is applied to each
%   element of X independently. M and T must be compatible with X in the same
%   sense as .*: one must be a scalar, or they must have identical size.
%
%   Disciplined convex programming information:
%       HUBER_POS is jointly convex in X and T. It is nondecreasing in X and
%       nonincreasing in T. Therefore, when used in CVX specifications, X
%       must be convex and T must be concave (or affine). Both must be real.

%
% Check arguments
%

narginchk(1,3);
if ~isreal( x ),
    error( 'First argument must be real.' );
end
if nargin < 2,
    M = 1;
elseif ~isreal( M ) || any( M( : ) <= 0 ),
    error( 'Second argument must be real and positive.' );
end
if nargin < 3,
    t = 1;
elseif ~isreal( t ),
    error( 'Third argument must be real.' );
end
sz = cvx_size_check( x, M, t );
if isempty( sz ),
    error( 'Sizes are incompatible.' );
end

%
% Compute result
%

y = max( x, 0 );
z = min( y, M );
y = t .* z .* ( 2 * y - z );
q = t <= 0;
if nnz( q ),
    if length( t ) == 1,
        y = Inf * ones( sy );
    else
        y( q ) = Inf;
    end
end

% Copyright 2005-2016 CVX Research, Inc. 
% See the file LICENSE.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.
