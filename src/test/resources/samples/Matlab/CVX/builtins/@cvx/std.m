function y = std( x, w, dim )

%STD    Internal cvx version.

if ~cvx_isaffine( x ),
    error( 'Disciplined convex programming error:\n    VAR is convex and nonmonotonic in X, so X must be affine.', 1 ); %#ok
elseif nargin > 1 && ~cvx_isconstant( w ),
    error( 'Weight vector must be constant.' );
end

try
    if nargin < 3, dim = []; end
    [ x, sx, sy, zx, zy, nx, nv, perm ] = cvx_reduce_size( x, dim ); %#ok
catch exc
    error( exc.message );
end

if nx > 1 && nv > 0,
    if nargin < 2 || numel( w ) == 1,
        if nargin == 2 && w,
            denom = nx;
        else
            denom = nx - 1;
        end
        % In theory we could just say y = mean(abs(x-mean(x))). However, by
        % adding an extra variable we preserve sparsity.
        cvx_begin
            variable xbar( 1, nv )
            denom * xbar == sum( x ); %#ok
            minimize( norms( x - ones(nx,1) * xbar ) / sqrt( denom ) );
        cvx_end
        y = cvx_optval;
    elseif numel( w ) ~= nx || ~isreal( w ) || any( w < 0 ),
        error( 'Weight vector expected to have %d nonnegative elements.', w );
    else
        sw = sum( w(:) );
        if sw == 0,
            error( 'Weight vector must not be all zeros.' );
        end
        w = w(:) / sw;
        cvx_begin
            variable xbar( 1, nv )
            xbar == sum( w' * x ); %#ok
            w = sqrt( w );
            minimize( norms( w( :, ones(1,nv) ) .* ( x - ones(nx,1) * xbar ) ) );
        cvx_end
        y = cvx_optval;
    end
elseif nx == 0,
    y = NaN( sy );
else
    y = zeros( sy );
end

%
% Reverse the reshaping and permutation steps
%

y = reshape( y, sy );
if ~isempty( perm ),
    y = ipermute( y, perm );
end

% Copyright 2005-2016 CVX Research, Inc.
% See the file LICENSE.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.
