function [ y, x ] = cvx_check_dimlist( x, emptyok )

% CVX_CHECK_DIMLIST Verifies the input is a valid dimension list.

% Copyright 2005-2016 CVX Research, Inc.
% See the file LICENSE.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.

if nargin < 2 || emptyok,
    xmin = 0;
else
    xmin = 1;
end
if isa( x, 'cell' ),
    nel = numel( x );
    xnew = zeros( 1, nel );
    fnan = false;
    y = false;
    for k = 1 : nel,
        if isempty( x{k} ),
            if fnan, return; end
            xnew( k ) = NaN;
            fnan = true;
        elseif isnumeric( x{k} ) && length( x{k} ) == 1,
            xnew( k ) = x{k};
        else
            return;
        end
    end
    x = xnew;
end
y = isnumeric( x ) && length( x ) == numel( x ) && isreal( x ) && nnz( isnan( x ) ) <= 1 && ~any( x < xmin ) && nnz( x ~= floor( x ) ) == nnz( isnan( x ) );
if y && nargout > 1,
    x = [ x( : )', 1, 1 ];
    x = x( 1 : max( [ 2, find( x ~= 1 ) ] ) );
end

% Copyright 2005-2016 CVX Research, Inc.
% See the file LICENSE.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.
