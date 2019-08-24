function a = eq( x, y )

%Disciplined convex programming information for EQ (==):
%   Both the left- and right-hand sides of an equality constraint must
%   be affine (or constant). If either side of the constraint is complex,
%   then the real and imaginary portions are constrained separately.
%
%Disciplined geometric programming information for EQ (>):
%   Both the left- and right-hand sides of an equality constraint must
%   be log-affine, which includes positive constants and monomials.

b = newcnstr( evalin( 'caller', 'cvx_problem', '[]' ), x, y, '==' );
if nargout, a = b; end

% Copyright 2005-2016 CVX Research, Inc.
% See the file LICENSE.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.
