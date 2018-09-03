function v = value( x )
global cvx___
v = cvxaff( x );
switch class( v ),
    case 'cvx',
        v = value( v, cvx___.y );
    case 'cell',
        for k = 1 : numel( v ),
            v{k} = value( v{k}, cvx___.y );
        end
end

% Copyright 2005-2016 CVX Research, Inc.
% See the file LICENSE.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.
