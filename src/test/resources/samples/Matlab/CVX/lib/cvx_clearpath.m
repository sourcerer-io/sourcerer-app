function cvx_clearpath( arg ) %#ok

%CVX_CLEARPATH   Clears the cvx path.
%   CVX_CLEARPATH removes the internal cvx directories from Matlab's path. CVX
%   does this automatically when a model is completed (i.e., after CVX_END), in
%   order to reduce potential naming conflicts with other packages. There is no
%   need to call this function during the normal use of CVX.

global cvx___
cvx_global
if nargin == 0,
    cvx___.path.hold = false;
end
if cvx___.path.hold,
    cvx_setspath;
else
    cvx_clearspath;
    if ~isempty( cvx___.path.string ),
        path(strrep(path,cvx___.path.string,''));
    end
    cvx___.path.active = false;
end

% Copyright 2005-2016 CVX Research, Inc.
% See the file LICENSE.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.
