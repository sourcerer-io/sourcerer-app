function [ i, j, v ] = find( x )

%Disciplined convex/geometric programming information for FIND:
%   When used in CVX models, FIND cannot deduce the numeric value of a
%   CVX variable. So it returns the indices of elements that are 
%   "structurally" nonzero; i.e., that are not *identically* zero.
%   This is similar to the concept of structural nonzeros in sparse
%   matrix factorizations. To illustrate the distinction, consider:
%      variable x(3);
%      x(2) == 0;
%      y = [x(1);0;x(3)];
%   In this case, FIND(x) returns [1;2;3] even though x(2) has been set
%   to zero in an equality constraint. (After all, the overall model may
%   be infeasible, in which case x(2) is arguably not zero.) However,
%   FIND(y) will return [1;3], because y(2) is identically zero.
%
%   When X is a CVX variable, the first two outputs of [I,J,V]=FIND(X) 
%   are constant, and the third is a CVX variable containing the 
%   structural nonzeros of X.
%
%   FIND(X) places no convexity restrictions on its argument.

ndxs = find( any( x.basis_, 1 ) );
ndxs = ndxs( : );

if nargout > 1,
    i = ndxs - 1;
    j = floor( i / x.size_(1) ) + 1;
    i = rem( i, x.size_(1) ) + 1;
else
	i = ndxs;
end	

if nargout > 2,
    v = reshape( cvx_subsref( x, ndxs ), length( ndxs ) );
end

% Copyright 2005-2016 CVX Research, Inc.
% See the file LICENSE.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.
