function cvx_optval = norms_largest( x, k, dim )

%NORMS_LARGEST Computation of multiple norm_largest() norms.
%   NORMS_LARGEST( X, K, DIM ) provides a means to compute the largest-k
%   norms of multiple vectors packed into a matrix or N-D vector. This is
%   useful for performing max-of-norms or sum-of-norms calculations.
%
%   If DIM is omitted, the norms are computed along the first non-singleton
%   dimension. 
%
%   See NORM_LARGEST.
%
%   Disciplined convex programming information:
%       NORMS_LARGEST is convex and non-monotonic, so its input must be affine.

narginchk(2,3);
sx = size( x );

%
% Check second argument
%

if ~isnumeric( k ) || ~isreal( k ) || length( k ) ~= 1,
    error( 'Second argument must be a real scalar.' );
end

%
% Check third argument
%

if nargin < 3 || isempty( dim ),
    dim = cvx_default_dimension( sx );
elseif ~cvx_check_dimension( dim, false ),
    error( 'Third argument must be a valid dimension.' );
end

%
% Perform computation
%

cvx_optval = sum_largest( abs( x ), k, dim );

% Copyright 2005-2016 CVX Research, Inc. 
% See the file LICENSE.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.
