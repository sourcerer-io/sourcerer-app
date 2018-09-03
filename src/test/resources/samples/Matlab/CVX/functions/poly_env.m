function y = poly_env( p, x )

%POLY_ENV Evaluate the convex or concave envelope of a polynomial.
%   POLY_ENV( P, X ) uses a semidefinite program to compute the value of the
%   convex or concave envelope of the polynomial represented by the vector
%   P. The format of the vector P is identical to that required by POLYVAL,
%   with two additional restrictions. First, the elements of P must be real
%   and finite. Second, the length of P must 0, 2, or odd (1,3,5,...)
%
%   If the polynomial described by P is convex or concave, then a call to
%   POLY_ENV( P, X ) produces the same result as POLYVAL( P, X ).
%
%   POLY_ENV looks at the first nonzero element of P (presumably, but not
%   necessarily, P(1)) to determine if a convex or concave envelope is to
%   be selected. If P(1)>0, then a convex envelope is produced---i.e., the
%   function that is the tightest convex lower bound for POLYVAL(P,X).
%   Otherwise, a concave envelope is produced---the function that is the
%   tightest concave upper bound for POLYVAL(P,X).
%
%   If the degree N of P is odd---except for the special case N==1---no
%   proper convex/concave envelope exists. Therefore, POLY_ENV returns an
%   error in such cases.
%
%   If X is an array, the result will be computed elementwise.
%
%   Disciplined convex programming information:
%       POLY_ENV(P,X) is convex or concave and nonmotonic in X; therefore,
%       in CVX expressions, X must be affine, unless the polynomial 
%       described by P has a degree of 0 or 1. P must be constant.

%
% Check the polynomial
%

sp = size( p );
if isempty( p ),
    p = zeros( 1, 0 );
elseif ~isa( p, 'double' ) || ~isreal( p ) || length( sp ) > 2 || ~any( sp == 1 ),
    error( 'First argument must be a non-empty real vector.' );
elseif any( isnan( p ) | isinf( p ) ),
    error( 'Inf and NaN not accepted here.' );
end
n = prod( sp );
if n > 2 && rem( n, 2 ) == 0,
    error( 'The length of the vector p must be odd.' );
end

%
% Check the second argument
%

if n > 1 && ( ~cvx_isaffine( x ) || ~isreal( x ) ),
    error( 'The second argument must be real and affine.' );
end

%
% Handle the special cases
%

sx = size( x );
ndxs = find( p );
if isempty( ndxs ),
    y = zeros( sx );
    return
else
    for k = ndxs(:)',
        pt = p( k : end );
        if ~any( isinf( pt ./ pt(1) ) ),
            p = pt;
            break;
        end
    end
end
n = length( p );
switch n,
    case 0,
        y = zeros(sx);
        return
    case 1,
        y = p(1) * ones(sx);
        return
    case 2,
        y = p(1) * x + p(2);
        return
    case 3,
        % Quadratic
        b2a = p(2) ./ ( 2 * p(1) );
        y = p(1) * ( square( x + b2a ) - b2a * b2a ) + p(3);
        return
    otherwise,
        if all( p(2:end) == 0 ),
            y = p(1) * ( x .^ (n-1) ) + p(end);
            return
        end
end

%
% Build and solve the SDP
%

degr  = n - 1;
deg2  = 0.5 * degr + 1;
nv    = prod( sx );
psign = sign(p(1));
p     = psign * reshape( p, 1, n );
cvx_begin sdp separable
    epigraph variable y(sx);
    variable P(deg2,deg2,sx) hankel;
    P >= 0; %#ok
    1 == P(1,1,:); %#ok
    x == reshape( P(2,1,:), sx ); %#ok
    y == reshape( p(end:-1:1) * [ reshape( P(1,:,:), deg2, nv ) ; reshape( P(2:end,end,:), deg2-1, nv ) ], sx ); %#ok
cvx_end

y = cvx_optval * psign;

% Copyright 2005-2016 CVX Research, Inc. 
% See the file LICENSE.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.
