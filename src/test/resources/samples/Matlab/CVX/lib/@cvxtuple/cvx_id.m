function y = cvx_id( x )
y = apply( @cvx_id, x );
switch class( y ),
    case 'struct',
        y = struct2cell( y );
        y = max( [ -Inf, y{:} ] );
    case 'cell',
        y = max( [ -Inf, y{:} ] );
end

% Copyright 2005-2016 CVX Research, Inc.
% See the file LICENSE.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.


