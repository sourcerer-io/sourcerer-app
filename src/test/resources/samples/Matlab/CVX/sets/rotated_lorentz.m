function cvx_optpnt = rotated_lorentz( sx, dim, iscplx )

%ROTATED_LORENTZ   Rotated real second-order cone.
%   ROTATED_LORENTZ(N), where N is a positive integer, creates a column
%   variable of length N and two scalar variables, and constrains them
%   to lie in a rotated second-order cone. That is, given the declaration
%       variables x(n) y z
%   the constraint
%       {x,y,z} == rotated_lorentz(n)
%   is equivalent to
%       norm(x,2) <= geo_mean([y,z])
%   except that using ROTATED_LORENTZ is more efficient.
%
%   ROTATED_LORENTZ(SX,DIM), where SX is a valid size vector and DIM is a
%   positive integer, creates an array variable of size SX and two 
%   array variables of size SY (see below) and applies the second-order cone
%   constraint along dimension DIM. That is, given the declarations
%       sy = sx; sy(min(dim,length(sx)+1))=1;
%       variables x(sx) y(sy) z(sz)
%   the constraint
%       {x,y,z} == rotated_lorentz(sx,dim)
%   is equivalent to
%       norms(x,2,dim) <= geo_mean(cat(dim,y,z),dim)
%   except, again, ROTATED_LORENTZ is more efficient. DIM is optional; if
%   it is omitted, the first non-singleton dimension is used.
%
%   ROTATED_LORENTZ(SX,DIM,CPLX) creates real second-order cones if CPLX is
%   FALSE, and complex second-order cones if CPLX is TRUE. The latter case
%   is equivalent to COMPLEX_ROTATED_LORENTZ(SX,DIM).
%
%   Disciplined convex programming information:
%       ROTATED_LORENTZ is a cvx set specification. See the user guide for
%       details on how to use sets.

%
% Check size vector
%

narginchk(1,3);
[ temp, sx ] = cvx_check_dimlist( sx, true );
if ~temp,
    error( 'First argument must be a dimension vector.' );
end

%
% Check dimension
%

nd = length( sx );
if nargin < 2 || isempty( dim ),
    dim = cvx_default_dimension( sx );
elseif ~cvx_check_dimension( dim, true ),
    error( 'Second argument must be a dimension (or zero).' );
elseif dim == 0 || dim > nd || sx( dim ) == 1,
    dim = find( sx == 1 );
    if isempty( dim ),
        dim = nd + 1;
    else
        dim = dim( 1 );
    end
end
if dim > nd,
    sx( end + 1 : dim ) = 1;
    nd = dim;
end

%
% Check complex flag
%

if nargin < 3 || isempty( iscplx ),
    iscplx = false;
elseif length( iscplx ) ~= 1,
    error( 'Third argument must be a scalar.' );
else
    iscplx = logical( iscplx );
end

%
% Build the cvx module
%

if iscplx,
    sx( dim ) = 2 * sx( dim );
end

if any( sx == 0 ),
    cvx_optpnt.x = cvx( sx, [] );
    sx( dim ) = 1;
    cvx_optpnt.y = nonnegative( sx );
    cvx_optpnt.z = nonnegative( sx );
elseif sx( dim ) == 1,
    cone = semidefinite( [ 2, 2, sx ] );
    cvx_optpnt.x = reshape( cone( 2, 1, : ), sx );
    cvx_optpnt.y = reshape( cone( 1, 1, : ), sx );
    cvx_optpnt.z = reshape( cone( 2, 2, : ), sx );
else
    sx( dim ) = sx( dim ) + 1;
    cone = lorentz( sx, dim );
    ndxs = cell( 1, nd );
    [ ndxs{:} ] = deal( ':' );
    ndxs{ dim } = 1 : sx( dim ) - 1;
    cvx_optpnt.x = cone.x( ndxs{:} );
    ndxs{ dim } = sx( dim );
    temp = cone.x( ndxs{:} );
    cvx_optpnt.y = cone.y + temp;
    cvx_optpnt.z = cone.y - temp;
end

if iscplx,
    cvx_optpnt.x = cvx_r2c( cvx_optpnt.x, dim );
end

cvx_optpnt = cvxtuple( cvx_optpnt );

% Copyright 2005-2016 CVX Research, Inc.
% See the file LICENSE.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.
