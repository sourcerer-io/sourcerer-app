function x = reshape( x, varargin )

%   Disciplined convex/geometric programming information for RESHAPE:
%       RESHAPE imposes no convexity restrictions on its arguments.

%
% Check size arguments
%

switch nargin,
    case {0,1},
        error( 'Not enough input arguments.' );
    case 2,
        [ temp, sz ] = cvx_check_dimlist( varargin{1}, true );
        if ~temp,
            error( 'Second argument must be a valid dimension list.' );
        end
    otherwise,
        [ temp, sz ] = cvx_check_dimlist( varargin, true );
        if ~temp,
            error( 'Second and subsequent arguments must be nonnegative integers.' );
        end
end

%
% Quick exit if the size remains the same
%

sx = x.size_;
if isequal( sx, sz ),
    return;
end

%
% Confirm compatible reshape
%

px = prod( sx );
tt = isnan( sz );
if any( tt ),
    if nnz( tt ) > 1,
        error( 'Size can only have one unknown dimension.' );
    end
    tmp = px / prod( sz( ~tt ) );
    if isnan( tmp ) || tmp ~= floor( tmp ),
        error( 'Product of known dimensions, %d, not divisible into total number of elements, %d.', prod( sz( ~tt ) ), px );
    end
    sz( tt ) = tmp;
elseif px ~= prod( sz ),
    error( 'To RESHAPE the number of elements must not change.' );
end

%
% Perform the resize
%

x = cvx( sz, x.basis_ );

% Copyright 2005-2016 CVX Research, Inc.
% See the file LICENSE.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.
