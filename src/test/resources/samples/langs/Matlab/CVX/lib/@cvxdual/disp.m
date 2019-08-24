function disp( x, prefix, iname )
if nargin < 2, prefix = ''; end
if nargin < 3, iname = ''; end
nm = cvx_subs2str( x.name_ );
nm = nm(2:end);
if ~isequal( nm, iname ),
    disp( [ prefix, 'cvx dual variable ', nm, ' (', type( x ), ')' ] );
else
    disp( [ prefix, 'cvx dual variable (', type( x ), ')' ] );
end

% Copyright 2005-2016 CVX Research, Inc.
% See the file LICENSE.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.
