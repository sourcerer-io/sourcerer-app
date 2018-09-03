function y = avg_abs_dev( x, dim )

%AVG_ABS_DEV    Internal cvx version.

if ~cvx_isaffine( x ),
    error( 'Disciplined convex programming error:\n    ABS_AVG_DEV is convex and nonmonotonic in X, so X must be affine.', 1 ); %#ok
end

try
	if nargin < 2, dim = []; end
	[ x, sx, sy, zx, zy, nx, nv, perm ] = cvx_reduce_size( x, dim ); %#ok
catch exc
	error( exc.message );
end

if nx > 1 && nv > 0,
    % In theory we could just say y = mean(abs(x-mean(x))). However, by
    % adding an extra variable we preserve sparsity.
    cvx_begin
        variable y( 1, nv );
        y == sum( x ) / nx; %#ok
        minimize( sum( abs( x - ones(nx,1) * y ) ) / nx );
    cvx_end
    y = cvx_optval;
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
