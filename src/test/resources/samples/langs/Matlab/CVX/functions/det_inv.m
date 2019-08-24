function cvx_optval = det_inv( X, p )

%DET_INV determinant of the inverse of an SPD matrix.
%   For a square matrix X, DET_INV(X) returns 1.0./DET(X) if X is symmetric
%   (real) or Hermitian (complex) and positive defininte, and +Inf otherwise.
%
%   This function can be used in many convex optimization problems that call
%   for LOG(DET(X)) instead. For example, if the objective function is
%      maximize(logdet(X))
%   then it can be replaced with
%      maximize(-det_inv(X))
%   and the same optimal point will be produced.
%
%   DET_INV(X,p) computes DET_INV(X)^p. p must be a positive real scalar.
%
%   Disciplined convex programming information:
%       DET_INV(X) is convex and nonmonotonic in X; therefore, when used in
%       CVX specifications, its argument must be affine.

narginchk(1,2);
n = size( X, 1 );
if ndims( X ) > 2, %#ok
    error( 'N-D arrays are not supported.' );
elseif size( X, 2 ) ~= n,
    error( 'Matrix must be square.' );
elseif nargin < 2,
    p = 1;
elseif ~isnumeric( p ) || ~isreal( p ) || numel( p ) ~=  1 || p <= 0,
    error( 'Second argument must be a positive scalar.' );
end

if nnz( X - X' ) ~= 0,

    cvx_optval = +Inf;

else

    n = size( X, 1 );
    [ R, q ] = chol( X );
    if q == 0,
        cvx_optval = prod(diag(R)).^(-p);
    else
        eigs = eig( X );
        if any( eigs <= 0 ),
            cvx_optval = +Inf;
        else
            cvx_optval = prod(eigs).^(-p);
        end
    end

end

% Copyright 2005-2016 CVX Research, Inc. 
% See the file LICENSE.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.
