function cvx_clearspath

%CVX_CLEARSPATH   Clears the cvx solver path.
%   CVX_CLEARSPATH removes the internal solver directories to the Matlab
%   path. CVX automatically clears the solver path after completion of a
%   model computation, so calling this function should not be necessary.
%   Nevertheless, we provide it for completeness and debugging.

global cvx___
osolv = cvx___.solvers.active;
if osolv,
    tstr = cvx___.solvers.list(osolv).path;
    if ~isempty( tstr ),
        path(strrep(path,tstr,''));
    end
    cvx___.solvers.active = 0;
end

% Copyright 2005-2016 CVX Research, Inc.
% See the file LICENSE.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.
