function y = subsref( x, S, cheat )
global cvx___
y = subsref( cvx___.problems( x.index_ ), S );

% Copyright 2005-2016 CVX Research, Inc.
% See the file LICENSE.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.
