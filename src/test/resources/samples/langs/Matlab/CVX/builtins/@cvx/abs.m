function y = abs( x )

%Disciplined convex/geometric programming information for ABS:
%   ABS(X) is convex and nonmonotonic in X. Therefore, when used in
%   DCPs, X must be affine. ABS(X) is not useful in DGPs, since all
%   log-convex and log-concave expressions are already positive.

%
% Determine the expression types
%

% 0 : convex, concave, invalid
% 1 : constant
% 2 : real affine
% 3 : complex affine
persistent remap
if isempty( remap ),
    remap_1 = cvx_remap( 'constant' );
    remap_2 = cvx_remap( 'real-affine' );
    remap_3 = cvx_remap( 'complex-affine' );
    remap_4 = cvx_remap( 'log-valid' );
    remap = remap_1 + ( 2 * remap_2 + 3 * remap_3 + 4 * remap_4 ) .* ~remap_1;
end
v = remap( cvx_classify( x ) );

%
% Process each type of expression one piece at a time
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
            error( 'Disciplined convex programming error:\n    Illegal operation: abs( {%s} ).', cvx_class( xt ) );
        case 1,
            % Constant
            cvx_optval = cvx( builtin( 'abs', cvx_constant( xt ) ) );
        case 2,
            % Real affine
            w = [];
            st = size( xt );
            cvx_begin
                epigraph variable w( st )
                { xt, w } == lorentz( st, 0 ); %#ok
            cvx_end
        case 3,
            % Complex affine
            w = [];
            st = size( xt );
            cvx_begin
                epigraph variable w( st )
                { xt, w } == complex_lorentz( st, 0 ); %#ok
            cvx_end
        case 4,
            % log-affine, log-convex
            cvx_optval = xt;
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
