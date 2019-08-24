function s = nnz( x )

%   Disciplined convex/geometric programming information for NNZ:
%      When used in CVX models, NNZ cannot deduce the numeric value of a
%      CVX variable, so it returns the number of "structurally" nonzero
%      elements; i.e., those that are not *identically* zero. This is
%      similar to the concept of structural nonzeros in sparse matrix
%      factorizations. To illustrate the distinction, consider:
%         variable x(3);
%         x(2) == 0;
%         y = [x(1);0;x(3)];
%      In this case, NNZ(x) returns 3, even though x(2) has been set to
%      zero in an equality constraint. (After all, the overall model may
%      be infeasible, in which case x(2) is arguably not zero.) However,
%      NNZ(y) returns 2, because y(2) is identically zero.

s = nnz( any( x.basis_, 1 ) );

% Copyright 2005-2016 CVX Research, Inc.
% See the file LICENSE.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.
