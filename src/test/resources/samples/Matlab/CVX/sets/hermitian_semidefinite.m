function cvx_optpnt = hermitian_semidefinite( n )

%HERMITIAN_SEMIDEFINITE   Complex Hermitian positive semidefinite matrices.
%    HERMITIAN_SEMIDEFINITE(N), where N is an integer, creates a complex 
%    Hermitian matrix variable of size [N,N] and constrains it to be 
%    positive semidefinite. Therefore, given the declaration
%       variable x(n,n) Hermitian
%    the constraint
%       x == hermitian_semidefinite(n)
%    is equivalent to
%       lambda_min(x) >= 0;
%    In fact, lambda_min is implemented in CVX using HERMITIAN_SEMIDEFINITE
%    for complex matrices.
%
%    HERMITIAN_SEMIDEFINITE(SX), where SX is a valid size vector, creates
%    an array variable of size SX and constrains each subarray along the 
%    leading two dimensions to be positive semidefinite. SX(1) and SX(2)
%    must be equal. Therefore, given the declaration
%       variable x(sx) Hermitian
%    the constraint
%       x == hermitian_semidefinite(sx)
%    is equivalent to
%       for k = 1:prod(sx(3:end)),
%          lambda_min(x(:,:,k)) >= 0;
%       end
%
%   Disciplined convex programming information:
%       SEMIDEFINITE is a cvx set specification. See the user guide for
%       details on how to use sets.

narginchk(1,1);
cvx_optpnt = semidefinite( n, true );

% Copyright 2005-2016 CVX Research, Inc. 
% See the file LICENSE.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.
