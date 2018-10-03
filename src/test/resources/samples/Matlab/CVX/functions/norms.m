function cvx_optval = norms( x, p, dim )

%NORMS   Computation of multiple vector norms.
%   NORMS( X ) provides a means to compute the norms of multiple vectors
%   packed into a matrix or N-D array. This is useful for performing
%   max-of-norms or sum-of-norms calculations.
%
%   All of the vector norms, including the false "-inf" norm, supported
%   by NORM() have been implemented in the NORMS() command.
%     NORMS(X,P)           = sum(abs(X).^P).^(1/P)
%     NORMS(X)             = NORMS(X,2).
%     NORMS(X,inf)         = max(abs(X)).
%     NORMS(X,-inf)        = min(abs(X)).
%   If X is a vector, these computations are completely identical to
%   their NORM equivalents. If X is a matrix, a row vector is returned
%   of the norms of each column of X. If X is an N-D matrix, the norms
%   are computed along the first non-singleton dimension.
%
%   NORMS( X, [], DIM ) or NORMS( X, 2, DIM ) computes Euclidean norms
%   along the dimension DIM. NORMS( X, P, DIM ) computes its norms
%   along the dimension DIM.
%
%   Disciplined convex programming information:
%       NORMS is convex, except when P<1, so an error will result if these
%       non-convex "norms" are used within CVX expressions. NORMS is
%       nonmonotonic, so its input must be affine.

%
% Check second argument
%

narginchk(1,3);
if nargin < 2 || isempty( p ),
    p = 2;
elseif ~isnumeric( p ) || numel( p ) ~= 1 || ~isreal( p ),
    error( 'Second argument must be a real number.' );
elseif p < 1 || isnan( p ),
    error( 'Second argument must be between 1 and +Inf, inclusive.' );
end
    
%
% Check third argument
%

sx = size( x );
if nargin < 3 || isempty( dim ),
    dim = cvx_default_dimension( sx );
elseif ~cvx_check_dimension( dim, false ),
    error( 'Third argument must be a valid dimension.' );
elseif isempty( x ) || dim > length( sx ) || sx( dim ) == 1,
    p = 1;
end

%
% Compute the norms
%

switch p,
    case 1,
        cvx_optval = sum( abs( x ), dim );
    case 2,
        cvx_optval = sqrt( sum( x .* conj( x ), dim ) );
    case Inf,
        cvx_optval = max( abs( x ), [], dim );
    otherwise,
        cvx_optval = sum( abs( x ) .^ p, dim ) .^ ( 1 / p );
end

% Copyright 2005-2016 CVX Research, Inc.
% See the file LICENSE.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.
