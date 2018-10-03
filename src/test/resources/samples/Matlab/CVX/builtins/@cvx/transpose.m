function y = transpose( x )

%   Disciplined convex/geometric programming information for TRANSPOSE:
%      The transpose operation may be applied to CVX variables without
%      restriction.

%
% Determine permutation
%

s = x.size_;
if length( s ) > 2,
    error( 'Transpose of an ND array is not defined.' );
end

%
% Permute the data
%

ndxs = 1 : prod( s );
ndx2 = reshape( ndxs, s ).';
b = x.basis_;
try
    b = b( :, ndx2 );
catch %#ok
    ndxs( ndx2( : ).' ) = ndxs;
    [ r, c, v ] = find( b );
    b = sparse( r, ndxs( c ), v, size( b, 1 ), size( b, 2 ) );
    clear r c v
end
y = cvx( size( ndx2 ), b );

% Copyright 2005-2016 CVX Research, Inc.
% See the file LICENSE.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.
