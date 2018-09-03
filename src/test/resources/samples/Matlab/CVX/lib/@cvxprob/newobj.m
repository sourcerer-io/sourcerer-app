function newobj( prob, dir, x )
narginchk(3,3);

persistent remap_min remap_max remap
if isempty( remap_max ),
    remap_min = cvx_remap( 'convex', 'log-convex' );
    remap_max = cvx_remap( 'concave', 'log-concave' );
    remap = cvx_remap( 'log-valid' ) & ~cvx_remap( 'constant' );
end

%
% Check problem
%

if ~isa( prob, 'cvxprob' ),
    error( 'First argument must be a cvxprob object.' );
end
global cvx___
p = prob.index_;
if ~isempty( cvx___.problems( p ).direction ),
	if isequal( dir, 'find' ),
        error( 'Objective functions cannot be added to sets.' );
    else
	    error( 'An objective has already been supplied for this problem.' );
	end
end

%
% Check direction
%

if ~ischar( dir ) || size( dir, 1 ) ~= 1,
    error( 'The second argument must be a string.' );
end

%
% Check objective expression
%

if ~isa( x, 'cvx' ) && ~isa( x, 'double' ) && ~isa( x, 'sparse' ),
    error( 'Cannot accept an objective of type ''%s''.', class( x ) );
elseif ~isreal( x ),
    error( 'Expressions in objective functions must be real.' );
elseif isempty( x ),
    warning( 'CVX:EmptyObjective', 'Empty objective.' );
end
cx = cvx_classify( x );
switch dir,
    case 'minimize',
	 	vx = remap_min( cx );
    case 'maximize',
	 	vx = remap_max( cx );
    otherwise,
        error( 'Invalid objective type: %s', dir );
end
if ~all( vx ),
    error( 'Disciplined convex programming error:\n   Cannot %s a(n) %s expression.', dir, cvx_class(x(vx==0),false,true) );
end

%
% Store the objective
%

vx = remap( cx );
if any( vx ),
    if all( vx ),
        x = log( x );
    else
        x( vx ) = log( x( vx ) );
    end
end
if isa( x, 'cvx' ),
    zndx = any( cvx_basis( x ), 2 );
    v = cvx___.problems( p ).t_variable;
    cvx___.problems( p ).t_variable = v | zndx( 1 : size( v, 1 ), : );
end
cvx___.problems( p ).objective = x;
cvx___.problems( p ).direction = dir;
cvx___.problems( p ).geometric = vx;

% Copyright 2005-2016 CVX Research, Inc.
% See the file LICENSE.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.
