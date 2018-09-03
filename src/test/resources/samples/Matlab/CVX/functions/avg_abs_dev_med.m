function y = avg_abs_dev_med( x, dim )

%AVG_ABS_DEV_MED   Average absolute deviation about the median.
%   For vectors, AVG_ABS_DEV_MED(X) is the average absolute deviation of X
%   about its median; that is, AVG_ABS_DEV_MED(X)=MEAN(ABS(X-MEDIAN(X))).
%   For matrices, AVG_ABS_DEV_MED(X) is a row vector containing the average
%   absolute deviation of each column. For N-D arrays, AVG_ABS_DEV_ME(X)
%   is the average absolute deviation of the elements along the first
%   non-singleton dimension of X.
%
%   AVG_ABS_DEV_MED(X,DIM) performs the computation along the dimension DIM. 
%
%   See also AVG_ABS_DEV.
%
%   Disciplined convex programming information:
%       AVG_ABS_DEV_MED is convex and nonmontonic in X. 
%       Therefore, X must be affine.
%      

sx = size( x );
if nargin < 2 || isempty( dim ),
    dim = find( sx ~= 1 );
    if isempty( dim ), dim = 1; else dim = dim( 1 ); end
end
nd = length( sx );
if nd >= dim && sx( dim ) > 1,
    y = sum( abs( x - median( x, dim ) ), dim ) / sx( dim );
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
