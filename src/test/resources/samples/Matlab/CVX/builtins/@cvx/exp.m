function y = exp( x )

%   Disciplined convex programming information:
%       EXP(X) is convex and nondecreasing in X. When used in CVX
%       expressions, X must be real. Typically, X must also be affine
%       or convex; X can also be concave, but this produces a log-concave
%       result with very limited usefulness.
%
%   Disciplined geometric programming information:
%       EXP(X) is typically not used in geometric programs. However,
%       EXP(X), where X is a monomial or posynomial, can be included in 
%       geometric programs wherever a posynomial would be appropriate.

global cvx___
narginchk(1,1);
cvx_expert_check( 'log', x );
            
%
% Determine the expression types
%

persistent remap
if isempty( remap ),
    remap_1 = cvx_remap( 'real' );
    remap_2 = cvx_remap( 'convex', 'concave' ) & ~remap_1;
    remap = remap_1 + 2 * remap_2;
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
            error( 'Disciplined convex programming error:\n    Illegal operation: exp( {%s} ).', cvx_class( xt ) );
        case 1,
            % Constant
            xt = cvx( exp( cvx_constant( xt ) ) );
        case 2,
            % Affine, convex, concave
            xt = sparsify( xt, 'exponential' );
            [ rx, cx, vx ] = find( xt.basis_ );
            tt = rx == 1;  rx( tt ) = [];
            cc = cx( tt ); cx( tt ) = [];
            vc = vx( tt ); % vx( tt ) = [];
            exps = cvx___.exponential( rx, 1 );
            tt = exps == 0;
            if any( tt ),
                n1 = unique( rx( tt ) );
                n2 = newvar( cvx___.problems( end ).self, '', length( n1 ) );
                [ n2, dummy ] = find( n2.basis_ ); %#ok
                cvx___.exponential( n1, 1 ) = n2( : );
                cvx___.logarithm( n2, 1 ) = n1( : );
                cvx___.vexity( n2 ) = 1;
                n2 = n2( cvx___.vexity( n1 ) < 0 );
                if ~isempty( n2 ),
                    cvx___.vexity( n2 ) = NaN;
                    cvx___.nan_used = true;
                    cvx___.canslack( n2 ) = +1;
                end
                exps = cvx___.exponential( rx, 1 );
                cvx___.exp_used = true;
            end
            nb = size( xt.basis_, 2 );
            bx = sparse( exps, cx, 1, full( max( exps ) ), nb );
            if ~isempty( cc ),
                bx = bx * diag(exp(sparse(cc,1,vc,nb,1)));
            end
            xt = cvx( xt.size_, bx );
        otherwise,
            error( 'Shouldn''t be here.' );
    end

    %
    % Store the results
    %

    if nv == 1,
        y = xt;
    else
        y = cvx_subsasgn( y, t, xt );
    end

end

% Copyright 2005-2016 CVX Research, Inc.
% See the file LICENSE.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.
