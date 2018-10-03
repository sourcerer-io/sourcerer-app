function cvx_optval = sqrt( x )

%   Discipined convex programming information for SQRT:
%      SQRT(X) is log-concave and nondecreasing in X. Therefore, when used
%      in DCPs, X must be concave (or affine).
%   
%   Disciplined geometric programming information for SQRT:
%      SQRT(X) is log-log-affine and nondecreasing in X. Therefore, when
%      used in DGPs, X may be log-affine, log-convex, or log-concave.

narginchk(1,1);

%
% Determine the expression types
%

% 0 : affine complex, convex, invalid
% 1 : constant
% 2 : concave, real affine
persistent remap
if isempty( remap ),
    remap_1 = cvx_remap( 'constant' );
    remap_2 = cvx_remap( 'real-affine', 'concave' );
    remap_3 = cvx_remap( 'log-convex', 'log-concave' );
    remap = remap_1 + ( 2 * remap_2 + 3 * remap_3 ) .* ~remap_1;
end
v = remap( cvx_classify( x ) );

%
% Perform the computations for each expression type separately
%

vu = sort( v(:) );
vu = vu([true;diff(vu)~=0]);
nv = length( vu );
sx = x.size_;
if nv ~= 1,
    y = cvx( sx, [] );
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
            error( 'Disciplined convex programming error:\n    Illegal operation: sqrt( {%s} ).', cvx_class( xt, true, true ) );
        case 1,
            % Constant
            cvx_optval = cvx( builtin( 'sqrt', cvx_constant( xt ) ) );
        case 2,
            % Real affine, concave
            w = [];
            st = size( xt ); %#ok
            cvx_begin
                hypograph variable w( st );
                square( w ) <= xt; %#ok
            cvx_end
        case 3,
            % Monomial, posynomial
            cvx_optval = exp( 0.5 * log( xt ) );
        otherwise,
            error( 'Shouldn''t be here.' );
    end

    %
    % Store the results
    %

    if nv == 1,
        y = cvx_optval;
    else
        y = cvx_subsasgn( y, t, cvx_optval );
    end

end

% Copyright 2005-2016 CVX Research, Inc.
% See the file LICENSE.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.
