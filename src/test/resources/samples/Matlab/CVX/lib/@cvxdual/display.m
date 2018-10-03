function display( x )
nm = inputname(1);
long = ~isequal(get(0,'FormatSpacing'),'compact');
if long, disp( ' ' ); end
disp([nm ' =']);
if long, disp( ' ' ); end
disp(x,'    ',nm);
if long, disp( ' ' ); end

% Copyright 2005-2016 CVX Research, Inc. 
% See the file LICENSE.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.
