function y = real( x )

%   Disciplined convex/geometric programming information for REAL:
%      REAL(X) may be freely applied to any CVX expression. However,
%      since REAL(X)=X for all real expressions (including convex,
%      concave, log-convex, and log-concave), it is only useful in
%      the complex affine case.

y = cvx( x.size_, real( x.basis_ ) );

% Copyright 2005-2016 CVX Research, Inc.
% See the file LICENSE.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.
