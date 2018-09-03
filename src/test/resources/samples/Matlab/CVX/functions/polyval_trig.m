function y = polyval_trig( p, x )

%POLYVAL_TRIG Evaluate a trigonometric polynomial.
%   Y = POLYVAL_TRIG(P,X) returns the value of a trigonometric polynomial P
%   evaluated at X. P is a vector of length N+1 whose elements are the
%   coefficients of the polynomial in descending powers.
%
%       Y = REAL(P(1)*W^N + P(2)*W^(N-1) + ... + P(N)*W + P(N+1))
% 
%   where W = EXP(-SQRT(-1)*X). For real X, this equals
%
%       Y = REAL(P(1))*COS(W*N)+IMAG(P(1))*SIN(W*N) + ...
%              REAL(P(2))*COS(W*(N-1))+IMAG(P(2))*SIN(W*(N-1)) + ...
%              ... + REAL(P(N))*COS(W) + IMAG(P(N))*SIN(W) + REAL(P(N+1)).
%
%   Note that IMAG(P(N+1)) is ignored. If X is a matrix or vector, the
%   polynomial is evaluated at all points in X.
%
%   Disciplined convex programming information:
%       POLYVAL_TRIG is linear in P and nonconvex/nonconcave in X.
%       Therefore, when used in CVX specifications, P must be affine and
%       X must be constant. Certain values of X may allow P to be convex
%       or concave as well, but not so for all values of X.

sp = size( p );
if isempty( p ),
    p = zeros( 1, 0 );
elseif length( sp ) > 2 || ~any( sp == 1 ),
    error( 'First argument must be a vector.' );
end
n = length( p );
sx = size(x);

if ~cvx_isconstant( x ),
    error( 'Second argument must be constant.' );
else
    x = cvx_constant( x );
end

nx = numel( x );
xx = reshape( x, nx, 1 );
[ ii, jj, vv ] = find( p );
nv = length( vv );
vv = reshape( vv, nv, 1 );
xx = xx * reshape( n - ( ii + jj - 1 ), 1, nv );
xx = exp( sqrt(-1) * xx );
y  = real( xx ) * real( vv ) + imag( xx ) * imag( vv );
y  = reshape( y, sx );

% Copyright 2005-2016 CVX Research, Inc. 
% See the file LICENSE.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.
