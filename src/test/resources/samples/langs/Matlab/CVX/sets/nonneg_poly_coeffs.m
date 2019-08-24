function coeffs = nonneg_poly_coeffs( deg, trig, mm ) %#ok

%NONNEG_POLY_COEFFS   Coefficients of nonnegative degree-n polynomials. 
%   NONNEG_POLY_COEFFS(DEG), where DEG is a nonnegative integer, creates a
%   vector variable of length DEG+1 and treats its values as
%   coefficients of a polynomial (in the same sense as POLYVAL). It then
%   constrains those coefficients to guarantee that the resulting
%   polynomial will be nonnegative over the entire real line. That is, 
%   given a declaration
%       variable p(deg+1)
%       p == nonneg_poly_coeffs(deg)
%   the value of P that results will satisfy POLYVAL(P,X)>=0 for any real
%   value of X.
%
%   NONNEG_POLY_COEFFS(DEG,MM), where MM is a real vector of length 2,
%   constrains nonnegativity only over the interval MM(1) <= X <= MM(2).
%   That is, given a declaration
%       variable p(deg+1)
%       p == nonneg_poly_coeffs(deg,mm)
%   the value of P that results will satisfy POLYVAL(P,X)>=0 for any real
%   value of X between MM(1) and MM(2), inclusive. It may be negative
%   outside that interval. Note that MM(1) must be less than MM(2) for
%   this constraint to have any effect.
%
%   NONNEG_POLY_COEFFS(DEG,'TRIG') and NONNEG_POLY_COEFFS(DEG,MM,'TRIG')
%   create sets of coefficients of nonnegative *trigonometric* polynomials.
%   That is, given the declaration
%      variable p(deg+1)
%      p == nonneg_poly_coeffs(deg,true)
%   the value of P that resutls will satisfy 
%      REAL(POLYVAL(P,EXP(-SQRT(-1)*X)))>=0 
%   for any value of X.
%
%   Disciplined convex programming information:
%       NONNEG_POLY_COEFFS is a cvx set specification. See the user guide
%       for details on how to use sets.

narginchk(1,3);

 
%
% Check degree argument
%

if ~cvx_check_dimension( deg, true ),
    error( 'Argument must be a nonnegative integer.' );
end

%
% Check trig argument
%

switch nargin,
    case 1,
        mm = [];
        trig = false;
    case 2,
        if isequal( trig, 'trig' ),
            trig = true;
            mm = [];
        else
            mm = trig;
            trig = false;
        end
    case 3,
        if ~isequal( trig, 'trig' ),
            error( 'Second argument must be a range, or ''trig''.' );
        end
        trig = true;
end

%
% Check range argument
%
    
if isempty( mm ),
    mm = [ -Inf, +Inf ];
elseif ~isa( mm, 'double' ) || ~isreal( mm ) || numel( mm ) ~= 2,
    error( 'Second argument, if supplied, must be a range [ xmin xmax ].' );
elseif any( mm(1) == mm(2) & isinf( mm(1) ) ),
    error( 'Intervals [-Inf,-Inf] and [Inf,Inf] are not accepted.' );
end

%
% Construct set
%

if trig,
    
    %
    % Trigonometric
    %
    
    cvx_begin set
        variable coeffs(deg+1) complex;
        if mm(1) == mm(2),
            % Positive at a single point
            polyval_trig( coeffs, mm(1) ) >= 0; %#ok
        elseif mm(2) > mm(1) + 2 * pi,
            % Positive over the entire unit circle
            [ii,jj,vv] = find(hermitian_semidefinite(deg+1));
            coeffs == sparse( deg+1-abs(ii-jj), 1, vv ); %#ok
        elseif mm(2) > mm(1),
            % Positive over a subset of the unit circle
            a = exp( 1i * ( 0.5 * ( mm(2) + mm(1) ) ) );
            b = cos( 0.5 * ( mm(2) - mm(1) ) );
            coeffs1 = nonneg_poly_coeffs(deg,'trig');
            coeffs2 = nonneg_poly_coeffs(deg-1,'trig');
            coeffs == coeffs1 ...
                + [ (0.5*a)*coeffs2 ; 0 ] ...
                + [ 0 ; 0 ; (0.5*conj(a))*coeffs2(1:end-1) ] ...
                + [ zeros(deg-1,1) ; (0.5*a)*conj(coeffs2(end)) ; 0 ] ...
                - [ 0 ; b*coeffs2 ]; %#ok
        end
    cvx_end
    
else        
    
    %
    % Non-trigonometric
    %

    cvx_begin set
        variable coeffs(deg+1);
        if mm(1) == mm(2),
            % Positive at a single point
            polyval( coeffs, mm(1) ) >= 0; %#ok
        elseif mm(1) == -Inf,
            isodd = rem(deg,2);
            deg2 = floor(0.5*deg) + 1;
            [ii,jj,vv] = find(semidefinite(deg2));
            coeffs1 = sparse(ii+jj-1+isodd,1,vv);
            if mm(2) == +Inf,
                % [ -Inf, +Inf ]
                coeffs == coeffs1; %#ok
            else
                % [ -Inf, mm(2) ]
                coeffs2 = nonneg_poly_coeffs(deg-1);
                coeffs == coeffs1 - [ coeffs2 ; 0 ] + [ 0 ; mm(2) * coeffs2 ]; %#ok
            end
        elseif mm(2) == +Inf,
            % [ mm(1), +Inf ]
            coefff1 = nonneg_poly_coeffs(deg); %#ok
            coeffs2 = nonneg_poly_coeffs(deg-1);
            coeffs == coeffs1 + [ coeffs2 ; 0 ] - [ 0 ; mm(1) * coeffs2 ]; %#ok
        elseif mm(1) < mm(2),
            % [ mm(1), mm(2) ]
            coeffs1 = nonneg_poly_coeffs(deg);
            coeffs2 = nonneg_poly_coeffs(deg);
            [ 0 ; coeffs ] == ...
                + [ coeffs1 ; 0 ] - [ 0 ; mm(1) * coeffs1 ] ...
                - [ coeffs2 ; 0 ] + [ 0 ; mm(2) * coeffs2 ]; %#ok
        end
    cvx_end

end

% Copyright 2005-2016 CVX Research, Inc. 
% See the file LICENSE.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.
