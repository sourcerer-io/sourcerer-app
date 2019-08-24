function y = cvx_id( x )
y = cellfun( @cvx_id, x );
if isempty( y ),
    y = -Inf;
else
    y = max( y( : ) );
end

% Copyright 2005-2016 CVX Research, Inc.
% See the file LICENSE.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.
