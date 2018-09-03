function op = smooth_stack( varargin )

% OP = SMOOTH_STACK( S1, S2, S3, ..., SN )
%    "Stacks" N smooth functions S1, S2, S3, ..., SN together to create
%    a single smooth function that operates on an N-tuple. Returns a
%    function handle ready to be used in TFOCS.

args = varargin;
while isa( args, 'cell' ) && numel( args ) == 1,
    args = args{1};
end
if isempty( args ),
    op = @smooth_zero;
elseif isa( args, 'function_handle' ),
    op = args;
elseif ~isa( args, 'cell' ),
    error( 'Expected one or more smooth function handles.' );
else
    op = @(varargin)smooth_stack_impl( args, varargin{:} );
end

function [ f, g ] = smooth_stack_impl( smooth, x )

np = numel(smooth);
x = cell( x );
if nargout > 1,
    f = zeros( 1, np );
    g = cell( 1, np );
    for k = 1 : np,
        [ f(k), g{k} ] = smooth{k}( x{k} );
    end
    f = sum( f );
    g = tfocs_tuple( g );
else
    f = 0;
    for k = 1 : np,
        f = f + smooth{k}( x{k} );
    end
end

% TFOCS v1.3 by Stephen Becker, Emmanuel Candes, and Michael Grant.
% Copyright 2013 California Institute of Technology and CVX Research.
% See the file LICENSE for full license information.
