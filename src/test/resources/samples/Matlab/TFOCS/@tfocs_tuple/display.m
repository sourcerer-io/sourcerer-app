function display( x )

% DISPLAY	Automatic display.

long = ~isequal(get(0,'FormatSpacing'),'compact');
if long, disp( ' ' ); end
disp([inputname(1) ' =']);
if long, disp( ' ' ); end
disp(x,'    ',inputname(1))
if long, disp( ' ' ); end

% TFOCS v1.3 by Stephen Becker, Emmanuel Candes, and Michael Grant.
% Copyright 2013 California Institute of Technology and CVX Research.
% See the file LICENSE for full license information.
