function z = newtemp( prob, siz )

% NEWTEMP Creates a temporary variable.

global cvx___
vstr = cvx___.problems( prob.index_ ).variables;
if isfield( vstr, 'temp_' ),
    ndx = length( vstr.temp_ );
else
    ndx = 0;
end
base = struct( 'type', { '.', '{}' }, 'subs', { 'temp_', { ndx + 1 } } );
z = newvar( prob, base, siz );

% Copyright 2005-2016 CVX Research, Inc.
% See the file LICENSE.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.
