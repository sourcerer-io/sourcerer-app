function y = imag( x )

%Disciplined convex/geometric programming information for IMAG:
%   IMAG(X) may be freely applied to any CVX expression. Of course,
%   IMAG(X)=0 for all real expressions (including convex, concave,
%   log-convex, and log-concave), so it is primarily useful in the
%   complex affine case.

y = cvx( x.size_, imag( x.basis_ ) );

% Copyright 2005-2016 CVX Research, Inc.
% See the file LICENSE.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.
