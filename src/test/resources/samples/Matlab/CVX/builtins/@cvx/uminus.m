function z = uminus( x )

%   Disciplined convex programming information for UMINUS (-):
%      Unary minus may be used in DCPs without restrictions---with the
%      understanding, of course, that it produces a result with the 
%      opposite cuvature to its argument; i.e., the negative of a convex
%      expression is concave, and vice versa.
%
%   Disciplined geometric programming information for UMINUS(-):
%      Negation of non-constant values may not be used in disciplined
%      geometric programs.

persistent remap
if isempty( remap ),
    remap = cvx_remap( 'invalid', 'log-concave' ) & ~cvx_remap( 'log-affine' );
end
tt = remap( cvx_classify( x ) );
if nnz( tt ),
    xt = cvx_subsref( x, tt );
    error( 'Disciplined convex programming error:\n    Illegal operation: - {%s}', cvx_class( xt ) );
end

z = cvx( x.size_, -x.basis_ );

% Copyright 2005-2016 CVX Research, Inc.
% See the file LICENSE.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.
