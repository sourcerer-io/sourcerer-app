function y = end( x, k, n )

%Disciplined convex/geometric programming information for END:
%   The use of END as an array subscript (e.g., X(:,end)) is identical
%   with CVX variables as it is for numeric vectors and arrays.

sz = size( x );
nz = length( sz );
if k > nz,
    y = 1;
elseif k < n || nz <= n,
    y = sz( k );
else
    y = prod( sz( k : end ) );
end

% Copyright 2005-2016 CVX Research, Inc.
% See the file LICENSE.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.
