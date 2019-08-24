function y = avg_abs_dev( x, dim )

%AVG_ABS_DEV   Average absolute deviation (about the mean).
%   For vectors, AVG_ABS_DEV(X) is the average absolute deviation of X
%   about its mean; that is, AVG_ABS_DEV(X)=MEAN(ABS(X-MEAN(X))). For
%   matrices, AVG_ABS_DEV(X) is a row vector containing the average
%   absolute deviation of each column. For N-D arrays, AVG_ABS_DEV(X)
%   is the average absolute deviation of the elements along the first
%   non-singleton dimension of X.
%
%   AVG_ABS_DEV(X,DIM) performs the computation along the dimension DIM. 
%
%   See also AVG_ABS_DEV_MED.
%
%   Disciplined convex programming information:
%       AVG_ABS_DEV is convex and nonmontonic in X. 
%       Therefore, X must be affine.
%      

sx = size( x );
if nargin < 2 || isempty( dim ),
    dim = find( sx ~= 1 );
    if isempty( dim ), dim = 1; else dim = dim( 1 ); end
end
nd = length( sx );
if nd >= dim && sx( dim ) > 1,
    scale = 1.0 ./ sx( dim );
    y = sum( abs( x - sum( x, dim ) * scale ), dim ) * scale;
elseif length( sx ) < dim || sx( dim ) == 1,
    y = zeros( sx );
else
    sx( end + 1 : nd ) = 1;
    sx( dim ) = 1;
    y = NaN( sy );
end

% Copyright 2005-2016 CVX Research, Inc. 
% See the file LICENSE.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.

