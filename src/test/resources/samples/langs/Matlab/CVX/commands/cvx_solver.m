function [ sout, slist ] = cvx_solver( sname )

%CVX_SOLVER    CVX solver selection.
%   CVX_SOLVER <solver_name> or CVX_SOLVER('<solver_name>')
%   selects the named solver the CVX uses to solve models. The solver name
%   is case-insensitive; so, for example, both 'SeDuMi' and 'sedumi' will
%   select the same solver.
%
%   When CVX is first installed, the solver SDPT3 is selected as the
%   default. For most problems, this will be a good choice; nevertheless,
%   no solver is perfect, so if you encounter issues you may wish to
%   experiment with other solvers.
%
%   There are two ways to use the CVX_SOLVER command. If you use it within
%   a model---that is, between the statements CVX_BEGIN and CVX_END---then
%   the new solver selection will apply only to that particular model. For
%   instance, if the default solver is SDPT3, then the following structure
%   will solve a single model using SeDuMi instead:
%       cvx_begin
%           cvx_solver sedumi
%           variables ...
%           ...
%       cvx_end
%   On the other hand, if CVX_SOLVER is called *outside* of a model, then
%   the change will apply for all subsequent models, or until you call 
%   CVX_SOLVER once again.
%
%   [ SOLVER, SOLVER_LIST ] = CVX_SOLVER returns the name of the current
%   solver, and a cell array containing the names of all available choices.
%
%   Calling CVX_SOLVER with no input or output arguments produces a listing
%   of the solvers that CVX currently recognized, and an indication of the
%   current solver selection and/or the default.

global cvx___
cvx_global
if nargin,
    if isempty( sname ),
        sname = 'default';
    elseif ~ischar( sname ) || size( sname, 1 ) ~= 1,
        error( 'Argument must be a string.' );
    end
    try
        snumber = cvx___.solvers.map.(lower(sname));
    catch
        error( 'Unknown, unusable, or missing solver: %s', sname );
    end
    if ~isempty( cvx___.solvers.list(snumber).error ),
        error( 'Solver unusable due to prior errors: %s', sname );
    end
    if isempty( cvx___.problems ),
        cvx___.solvers.selected = snumber;
    elseif ~isa( evalin( 'caller', 'cvx_problem', '[]' ), 'cvxprob' ),
        error( 'The global CVX solver selection cannot be changed while a model is being constructed.' );
    else
        cvx___.problems(end).solver.index = snumber;
    end
    if cvx___.solvers.active,
        cvx_setspath;
    end
elseif nargout == 0,
    solvers = cvx___.solvers;
    snames = solvers.names;
    statvec = [ 0, solvers.map.default, solvers.active ];
    statstr = { 'selected', 'default', 'active' };
    if ~isempty( cvx___.problems ),
        statvec(1) = cvx___.problems(end).solver.index;
    else
        statvec(1) = solvers.selected;
    end
    fprintf( '\n' );
    dash = '-';
    solvers = solvers.list;
    nsolv = length( solvers );
    lens = [4,6,7,8];
    for k = 1 : nsolv,
        if isempty( solvers(k).error ),
            nstat = statstr(k==statvec);
            if ~isempty(nstat),
                nstat = sprintf( '%s,', nstat{:} );
                nstat = nstat(1:end-1);
            end
        else
            nstat = 'disabled';
        end
        lens = max( lens, [ length(snames{k}), length(nstat), length(solvers(k).version), length(solvers(k).location) ] );
    end
    fmt = sprintf( '   %%-%ds   %%-%ds   %%-%ds   %%s\\n', lens(1), lens(2), lens(3) );
    fprintf( fmt, 'Name', 'Status', 'Version', 'Location' ); %#ok
    fprintf( '%s\n', dash(ones(1,sum(lens)+15)) );
    for k = 1 : nsolv,
        if isempty( solvers(k).error ),
            nstat = statstr(k==statvec);
            if ~isempty(nstat),
                nstat = sprintf( '%s,', nstat{:} );
                nstat = nstat(1:end-1);
            else
                nstat = '';
            end
        else
            nstat = 'disabled';
        end
        fprintf( fmt, snames{k}, nstat, solvers(k).version, solvers(k).location );
    end
    fprintf( '\n' );
end
if nargout > 0,
    sout = cvx___.solvers.list(cvx___.solvers.selected).name;
    slist = cvx___.solvers.names;
end

% Copyright 2005-2016 CVX Research, Inc.
% See the file LICENSE.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.
