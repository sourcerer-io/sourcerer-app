function y = square( x )

%SQUARE   Internal cvx version.

% 0 : all others
% 1 : constant
% 2 : real affine
% 3 : monomial, posynomial
narginchk(1,1);
persistent remap
if isempty( remap ),
    remap1 = cvx_remap( 'constant' );
    remap2 = cvx_remap( 'affine' ) & ~remap1;
    remap3 = cvx_remap( 'log-valid' ) & ~remap1;
    remap  = remap1 + 2 * remap2 + 3 * remap3;
end
v = remap( cvx_classify( x ) );

%
% Perform the computations for each expression type separately
%

vu = sort( v(:) );
vu = vu([true;diff(vu)~=0]);
nv = length( vu );
if nv ~= 1,
    y = cvx( size( x ), [] );
end
for k = 1 : nv,

    %
    % Select the category of expression to compute
    %

    vk = vu( k );
    if nv == 1,
        xt = x;
    else
        t = v == vk;
        xt = cvx_subsref( x, t );
    end

    %
    % Perform the computations
    %

    switch vk,
        case 0,
            % Invalid
            error( 'Disciplined convex programming error:\n    Illegal operation: square( {%s} ).', cvx_class( xt, true, true ) );
        case 1,
            % Constant
            yt = cvx_constant( xt );
            yt = cvx( yt .* yt );
        case 2,
            % Real affine
            yt = quad_over_lin( xt, 1, 0 );
        case 3,
            % Monomial, posynomial
            yt = exp( 2 * log( xt ) );
        otherwise,
            error( 'Shouldn''t be here.' );
    end

    %
    % Store the results
    %

    if nv == 1,
        y = yt;
    else
        y = cvx_subsasgn( y, t, yt );
    end

end

% Copyright 2005-2016 CVX Research, Inc.
% See the file LICENSE.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.
