function y = cvx_recip( x )

%RECIP   Internal cvx version.

%
% Determine the expression types
%

narginchk(1,1);
persistent remap
if isempty( remap ),
    remap_1 = cvx_remap( 'constant' ) & ~cvx_remap( 'zero' );
    remap_2 = cvx_remap( 'log-valid' ) & ~remap_1;
    remap = remap_1 + 2 * remap_2;
end
vr = remap( cvx_classify( x ) );
vu = sort( vr(:) );
vu = vu([true;diff(vu)~=0]);
nv = length( vu );

%
% Process each result type one at a time
%

if nv ~= 1,
    y = cvx( x.size_, [] );
end
for k = 1 : nv,

    %
    % Select the category of expression to compute
    %

    if nv == 1,
        xt = x;
    else
        t = vr == vu( k );
        xt = cvx_subsref( x, t );
    end

    %
    % Perform the computations
    %

    switch vu( k ),
        case 0,
            % Invalid
            error( 'Disciplined convex programming error:\n    Cannot perform the operation recip( {%s} )', cvx_class( x, false, false, true ) );
        case 1,
            % Non-zero constant
            yt = cvx( 1.0 ./ cvx_constant( xt ) );
        case 2,
            % Monomial, posynomial
            yt = exp( -log( xt ) );
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
