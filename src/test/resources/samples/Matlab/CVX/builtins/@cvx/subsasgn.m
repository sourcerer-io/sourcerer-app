function x = subsasgn( x, S, y )

%   Disciplined convex/geometric programming information for SUBSASGN:
%      Subscripting can be used to change values of elements or slices
%      of CVX variables in the same manner as with numeric arrays. All
%      conventions are preserved, including the colon ':' and 'end'
%      notation, as well as the ability to "expand" a CVX variable by
%      assigning a value to a location outside of its current dimensions
%      (e.g., X(end+1)=0).
%   
%      One notable exception is this: if the right-hand side is a CVX
%      expression, then the left-hand side must be as well. So, for 
%      example, the following will fail:
%         variable x;
%         y = ones(3,1);
%         y(2) = x;
%      This is because MATLAB does not know how to automatically promote
%      'y' to a CVX variable so that it can accept 'x' as an element. If
%     you want
%      to accomplish something like this, you must manually convert y into a
%      CVX variable first, as follows:
%         variable x;
%         y = cvx(ones(3,1));
%         y(2) = x;

narginchk(3,3);

%
% Test subscripts
%

szx = size( x );
szy = size( y );
nlx = prod( szx );
try
    temp = reshape( 1 : nlx, szx );
    ndx_x = builtin( 'subsasgn', temp, S, zeros( szy ) );
catch errmsg
    error( errmsg.identifier, errmsg.message );
end
szx_n = size( ndx_x );
if length( szx_n ) ~= length( szx ),
   szx_n(end+1:length(szx)) = 1;
   szx(end+1:length(szx_n)) = 1;
end

%
% Assign data
%

x = cvx( x );
bx = x.basis_;
if any( szx_n < szx ),
    bx = bx( :, ndx_x );
else
    if any( szx_n > szx ),
        bx( :, end + 1 ) = 0;
        ndx_x( ndx_x == 0 ) = size( bx, 2 );
        bx = bx( :, ndx_x );
        temp = reshape( 1 : prod( szx_n ), szx_n );
    end
    ndx_x = builtin( 'subsref', temp, S );
    ndx_x = ndx_x( : );
    nlz = length( ndx_x );
    y = cvx( y );
    by = y.basis_;
    nx = size( bx, 1 );
    [ ny, my ] = size( by );
    if nx < ny,
        if issparse( by ) && ~issparse( bx ), bx = sparse( bx ); end
        bx( ny, : ) = 0;
    elseif nx > ny,
        if issparse( bx ) && ~issparse( by ), by = sparse( by ); end
        by( nx, : ) = 0;
    end
    if my < nlz,
        by = by( :, ones( 1, nlz ) );
    end
    bx( :, ndx_x ) = by;
end

%
% Create the new object
%

x = cvx( szx_n, bx );

% Copyright 2005-2016 CVX Research, Inc.
% See the file LICENSE.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.
