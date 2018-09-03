function y = ipermute( x, order )

%   Disciplined convex/geometric programming information for IPERMUTE:
%      IPERMUTE(A,ORDER) imposes no convexity restrictions on A. ORDER
%      must be constant.

%
% Determine the permutation
%

s = x.size_;
ndxs = 1 : prod( s );
ndx2 = ipermute( reshape( ndxs, s ), order );

%
% Permute the data
%

b = x.basis_;
try
    b = b( :, ndx2 );
catch
    ndxs( ndx2( : ).' ) = ndxs;
    [ r, c, v ] = find( b );
    b = sparse( r, ndxs( c ), v, size( b, 1 ), size( b, 2 ) );
    clear r c v
end
y = cvx( size( ndx2 ), b );

% Copyright 2005-2016 CVX Research, Inc.
% See the file LICENSE.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.
