function y = cvx_readlevel( x )

global cvx___
s = size( x.basis_ );
[ r, c ] = find( x.basis_ );
y = max( sparse( r, c, cvx___.readonly( r ), s(1), s(2) ), [], 1 );
y = cvx_reshape( y, x.size_ );

% Copyright 2005-2016 CVX Research, Inc.
% See the file LICENSE.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.
