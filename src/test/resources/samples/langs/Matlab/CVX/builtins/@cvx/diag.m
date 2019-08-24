function y = diag( v, k )

%Disciplined convex/geometric programming information for DIAG:
%   DIAG imposes no convexity restrictions on its arguments.

switch nargin,
    case 0,
        error( 'Not enough arguments.' );
    case 1,
        k = 0;
    case 2,
        if ~isnumeric( k ) || k ~= floor( k ),
            error( 'Second argument must be an integer.' );
        end
end

s = size( v );
if length( s ) ~= 2,
    error( 'First input must be 2D.' );
end

if k < 0,
    absk = -k;
    roff = absk;
    coff = 0;
else
    absk = +k;
    roff = 0;
    coff = absk;
end

if any( s == 1 ),
    nn = prod( s );
    nel = nn + roff + coff;
    y = sparse( roff + 1 : roff + nn, coff + 1 : coff + nn, v, nel, nel );
elseif roff >= s(1) || coff >= s(2),
    y = sparse( 0, 1 );
else
    nel = min( s(1) - roff, s(2) - coff );
    nv = roff + ( coff - 1 ) * s(1) + ( 1 : nel ) * ( s(1) + 1 );
    y = reshape( cvx_subsref( v, nv ), nel, 1 );
end

% Copyright 2005-2016 CVX Research, Inc.
% See the file LICENSE.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.
