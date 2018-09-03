function cvx_setpath( arg ) %#ok

%CVX_SETPATH   Sets the cvx path.
%   CVX_SETPATH adds the internal cvx directories to Matlab's path so that the
%   CVX system can find the functions that they contain. There is no reason to 
%   call this function during normal use of CVX; it is done automatically as
%   needed. However, if you are debugging CVX, calling this function can help to
%   insure that breakpoints stay valid.

% Set the hold flag
global cvx___
cvx_global
if ~cvx___.path.active,
    s = warning('off'); %#ok
    path([cvx___.path.string,path]);
    warning(s);
    cvx___.path.active = true;
end
if nargin == 0,
    cvx___.path.hold = true;
end
if cvx___.path.hold,
    cvx_setspath;
end

% Copyright 2005-2016 CVX Research, Inc.
% See the file LICENSE.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.
