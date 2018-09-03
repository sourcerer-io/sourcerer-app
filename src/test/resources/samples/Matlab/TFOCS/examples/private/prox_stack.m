function op = prox_stack( varargin )

% OP = PROJ_STACK( P1, P2, P3, ..., PN )
%    "Stacks" N proximity functions P1, P2, P3, ..., PN together, to create
%    a single proximity function that operates on an N-tuple. Returns a
%    function handle ready to be used in 

args = varargin;
while isa( args, 'cell' ) && numel( args ) == 1,
    args = args{1};
end
if isempty( args ),
    op = @proj_Rn;
elseif isa( args, 'function_handle' ),
    op = args;
elseif ~isa( args, 'cell' ),
    error( 'Expected one or more projector function handles.' );
else
    op = @(varargin)proj_stack_impl( args, varargin{:} );
end

function [ v, x ] = proj_stack_impl( proj, y, t )

np = numel(proj);
no = nargout > 1;
ni = nargin > 2;
y = cell( y );
if no,
    v = zeros( 1, np );
    x = cell( 1, np );
else
    v = 0;
end
if ni && numel(t) == 1,
    t = t * ones(1,np);
end
switch 2 * no + ni,
case 0, % 1 input, 1 output    
    for k = 1 : np,
        v = v + proj{k}( y{k} );
    end
case 1, % 2 inputs, 1 output
    for k = 1 : np,
        v = v + proj{k}( y{k}, t(k) );
    end
case 2, % 1 input, 2 outputs
    for k = 1 : np,
        [ v(k), x{k} ] = proj{k}( y{k} );
    end
case 3, % 2 inputs, 2 outputs
    v = zeros( 1, np );
    x = cell( 1, np ); 
    for k = 1 : np,
        [ v(k), x{k} ] = proj{k}( y{k}, t(k) );
    end
end
if no,
    v = sum( v );
    x = tfocs_tuple( x );
end

% TFOCS v1.3 by Stephen Becker, Emmanuel Candes, and Michael Grant.
% Copyright 2013 California Institute of Technology and CVX Research.
% See the file LICENSE for full license information.
