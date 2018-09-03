function y = entr( x )

%ENTR   Scalar entropy.
%   ENTR(X) returns an array of the same size as X with the unnormalized
%   entropy function applied to each element:
%                { -X.*LOG(X) if X > 0,
%      ENTR(X) = { 0          if X == 0,
%                { -Inf       otherwise.
%   If X is a vector representing a discrete probability distribution, then
%   SUM(ENTR(X)) returns its entropy.
%
%   Disciplined convex programming information:
%       ENTR(X) is concave and nonmonotonic in X. Thus when used in CVX
%       expressions, X must be real and affine. Its use will effectively 
%       constrain X to be nonnegative: there is no need to add an
%       additional X >= 0 to your model in order to enforce this.

narginchk(1,1);
cvx_expert_check( 'entr', x );
y = -rel_entr( x, 1 );

% Copyright 2005-2016 CVX Research, Inc.
% See the file LICENSE.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.
