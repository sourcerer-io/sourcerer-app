function x = subsref( x, S )

%   Disciplined convex/geometric programming information for SUBSREF:
%      The use of subscripts to extract elements or "slices" of any CVX
%      variable is identical to their use with numeric arrays. All 
%      conventions are preserved, including the colon ':' and 'end'.

narginchk(2,2);

try
    ndxs = builtin( 'subsref', reshape( 1 : prod( x.size_ ), x.size_ ), S );
catch errmsg
    error( errmsg.identifier, errmsg.message );
end

x = cvx( size( ndxs ), x.basis_( :, ndxs ) );

% Copyright 2005-2016 CVX Research, Inc.
% See the file LICENSE.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.
