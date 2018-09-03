function spy( prob, reduce )
if nargin < 2 || ~reduce,
    A = extract( prob );
else
    A = eliminate( prob );
end
spy( A' );

% Copyright 2005-2016 CVX Research, Inc.
% See the file LICENSE.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.
