function cvx_setspath

%CVX_SETSPATH   Sets the cvx solver path.
%   CVX_SETSPATH adds the internal cvx solver directories to Matlab's path
%   so that the CVX system can find the functions that they contain. There 
%   is no reason to call this function during normal use of CVX; it is done
%   automatically as needed. However, if you are debugging CVX, calling
%   this function can help to insure that breakpoints stay valid.

global cvx___
osolv = cvx___.solvers.active;
if isempty( cvx___.problems ),
    nsolv = cvx___.solvers.selected;
else
    nsolv = cvx___.problems(end).solver.index;
end
if osolv ~= nsolv,
    opath = [];
    npath = [];
    needupd = false;
    if osolv,
        tstr = cvx___.solvers.list(osolv).path;
        if ~isempty( tstr ),
            opath = path;
            npath = strrep(opath,tstr,'');
            needupd = true;
        end
        cvx___.solvers.active = 0;
    end
    if nsolv,
        tstr = cvx___.solvers.list(nsolv).path;
        if ~isempty( tstr ),
            if isempty(opath), opath = path; end
            if isempty(npath), npath = opath; end
            npath = [ tstr, npath ];
            needupd = true;
        end
        cvx___.solvers.active = nsolv;
    end
    if needupd,
        path(npath);
    end
end

% Copyright 2005-2016 CVX Research, Inc.
% See the file LICENSE.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.
