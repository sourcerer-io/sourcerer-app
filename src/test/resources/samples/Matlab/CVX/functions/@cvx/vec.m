function x = vec( x )

% VEC   CVX implementation of vec

x.size_ = [prod(x.size_),1];

% Copyright 2005-2016 CVX Research, Inc.
% See the file LICENSE.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.
