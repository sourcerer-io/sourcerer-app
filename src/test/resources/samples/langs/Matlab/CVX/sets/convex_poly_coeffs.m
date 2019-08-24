function cvx_optpnt = convex_poly_coeffs( deg, mm ) %#ok

%CONVEX_POLY_COEFFS   Coefficients of convex degree-n polynomials. 
%   CONVEX_POLY_COEFFS(DEG), where DEG is a nonnegative integer, creates a
%   CVX vector variable of length DEG+1 and treats its values as
%   coefficients of a polynomial (in the same sense as POLYVAL). It then
%   constraints those coefficients to guarantee that the resulting
%   polynomial will be convex; that is, its second derivative will be
%   nonnegative over the entire real line. That is, given the declaration
%       variable p(deg+1)
%       p == convex_poly_coeffs(deg)
%   the value of P that results will satisfy
%       POLYVAL([DEG:-1:2].*[DEG-1:-1:1].*P(1:END-2),X)>=0
%   for any real value of X.
%
%   CONVEX_POLY_COEFFS(DEG,MM), where MM is a real vector of length 2,
%   constrains convexity only over the interval MM(1) <= X <= MM(2).
%   That is, given a declaration
%       variable p(deg+1)
%       p == nonneg_poly_coeffs(deg,mm)
%   the value of P that results will satisfy
%       POLYVAL([DEG:-1:2].*[DEG-1:-1:1].*P(1:END-2),X)>=0
%   between MM(1) and MM(2), inclusive. It may be negative outside that
%   interval. Note that MM(1) must be less than MM(2) for this constraint
%   to have any effect.
%
%   Disciplined convex programming information:
%       CONVEX_POLY_COEFFS is a cvx set specification. See the user guide
%       for details on how to use sets.

narginchk(1,2);

%
% Check argument
%

if ~cvx_check_dimension( deg, true ),
    error( 'Argument must be a nonnegative integer.' );
elseif rem( deg, 2 ) ~= 0 && deg ~= 1,
    error( 'Degree must be 0, 1, or even.' );
end

% Check range argument
%

if nargin < 2 || isempty( mm ),
    mm = [ -Inf, +Inf ];
else
    if ~isa( mm, 'double' ) || ~isreal( mm ) || ndims( mm ) > 2 || numel( mm ) ~= 2 && size( mm, 2 ) ~= 2, %#ok
        error( 'Second argument must be a range [ xmin xmax ] or a matrix of them.' );
    end
    mm = reshape( mm, 0.5 * numel( mm ), 2 );
    m1 = mm(:,1);
    m2 = mm(:,2);
    if any( ( m1 == m2 ) & isinf( m1 ) ),
        error( 'Intervals [-Inf,-Inf] and [+Inf,+Inf] are not accepted.' );
    end
end

%
% Construct set
%

cvx_begin set
    variable coeffs(deg+1);
    if deg >= 2,
        ((deg:-1:2).*(deg-1:-1:1))'.*coeffs(1:end-2,:) == nonneg_poly_coeffs(deg-2,mm); %#ok
    end
cvx_end

% Copyright 2005-2016 CVX Research, Inc. 
% See the file LICENSE.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.
