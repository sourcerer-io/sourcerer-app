function y = polyval( p, x )

%   Disciplined convex/geometric programming information for POLYVAL:
%      POLYVAL can be used with CVX variables in two ways:
%      -- If P is constant and X is a variable, then POLYVAL(P,X)
%         represents a polynomial function of X, p(X). If p(X) is affine
%         then the basic  DCP or DCP rules for sums and products apply.
%         If P is nonlinear then:
%         -- for DCPs, the polynomial must be convex or concave, and X
%            must be affine (such polynomials cannot be monotonic).
%         -- for DGPs, the elements of P must be nonnegative, in which
%            case p(X) is nondecreasing, so X must be log-convex.
%      -- If X is a constant and P is a variable, then POLYVAL(P,X)
%         performs a weighted sum of the elements of P. The weights are,
%         of course, [X^N,X^(N-1),...,X,1]. As in the affine case above,
%         then standard DCP or DGP rules for sums and products apply.

sp = size( p );
if isempty( p ),
    p = zeros( 1, 0 );
elseif length( sp ) > 2 || ~any( sp == 1 ),
    error( 'First argument must be a vector.' );
end
sx = size(x);

persistent remap
if isempty( remap ),
    remap_1 = cvx_remap( 'real-affine' );
    remap_2 = cvx_remap( 'log-convex' );
    remap = remap_1 + 2 * remap_2;
end

if cvx_isconstant( p ),
    p = cvx_constant( p );
    if cvx_isconstant( x ),
        y = cvx( polyval( p, cvx_constant( x ) ) );
        return
    end
    if any( isinf( p ) | isnan( p ) ),
        error( 'Inf and NaN not accepted here.' );
    end
    ndxs = find( p );
    if isempty( ndxs ),
        y = zeros( sx );
        return
    end
    for k = ndxs(:)',
        pt = p( k : end );
        if ~any( isinf( pt ./ pt(1) ) ),
            p = pt;
            break;
        end
    end
    n = length( p );
    switch length( p ),
        case 0,
            % Zero
            y = zeros(sx);
        case 1,
            % Constant
            y = cvx( p(1) * ones(sx) );
        case 2,
            % Affine
            y = p(1) * x + p(2);
        otherwise,
            vu = remap(cvx_classify(x));
            p = reshape( p, n, 1 );
            t0 = vu == 0;
            if any( t0 ),
                error( 'Disciplined convex programming error:\n    Illegal operation: polyval( p, {%s} ).', cvx_class( cvx_subsref( x, t0 ), false, true ) );
            end
            t1 = vu == 1;
            if any( t1 ),
                pd = roots( (n-2:-1:1).*(n-1:-1:2).*p(1:end-2,:)' );
                pd = pd( imag(pd) == 0 );
                if ~isempty( pd ),
                    pr = diff( [ 0, find(diff(sort(pd))~=0), length(pd) ] );
                    if any( rem( pr, 2 ) ),
                        error( 'Polynomials in DCPs must be affine, convex, or concave.' );
                    end
                end
            end
            t2 = vu == 2;
            if any( t2 ) && any( p < 0 ),
                error( 'Polynomials in DGPs must have nonnegative coefficients.' );
            end
            if any( t2 ),
                if all( t2 ),
                    y = x;
                else
                    y = cvx_subsref( x, t2 );
                end
                ny = numel(y);
                y = reshape( y, ny, 1 );
                q = find( p(1:end-2) );
                y = ( ( y * ones(1,length(q)) ) .^ ( ones(ny,1) * (n-q)' ) ) * p(q,:) + p(end-1) * y + p(end);
                if all( t2 ),
                    y = reshape( y, sx );
                else
                    y = cvx_subsasgn( x, t2, y );
                end
            end
            if all( t1 ),
                y = poly_env( p, x );
            elseif any( t1 ),
                y = cvx_subsasgn( y, t1, poly_env( p, cvx_subsref( x, t1 ) ) );
            end
    end
    
elseif cvx_isconstant( x ),
    
    n = length( p );
    [ ii, jj, vv ] = find( p );
    jj = ii + jj - 1;
    nv = length(vv);
    nx = prod( sx );
    y = reshape( x, nx, 1 ) * ones( 1, nv );
    y = y .^ ( ones( nx, 1 ) * (n-jj(:))' );
    y = reshape( y * reshape( vv, nv, 1 ), sx );
    
else
    
    error( 'At least one of the arguments must be constant.' );
    
end

% Copyright 2005-2016 CVX Research, Inc.
% See the file LICENSE.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.
