function cvx_optval = norm_largest( x, k )

%NORM_LARGEST Sum of the k largest magnitudes of a vector.
%   NORM_LARGEST( X, k ) computes the 'largest-k' norm; that is, it computes
%   the sum of the magnitudes of the k largest elements in X. X must
%   be a vector, and k must be a real scalar.
%
%   Disciplined convex programming information:
%       NORM_LARGEST is convex and nonmonotonic of X, though it is monotonic for
%       positive values of X. So when used in CVX expressions, X must be affine,
%       monomial, or posynomial. k must be a real scalar constant.

narginchk(2,2);
if ~any( size( x ) ~= 1 ),
    error( 'The first argument must be a vector.' );
elseif ~isnumeric( k ) || ~isreal( k ) || length( k ) ~= 1,
    error( 'Third argument must be a scalar.' );
else
    cvx_optval = sum_largest( abs( x ), k );
end

% Copyright 2005-2016 CVX Research, Inc. 
% See the file LICENSE.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.
