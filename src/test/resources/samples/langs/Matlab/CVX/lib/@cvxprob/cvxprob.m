function z = cvxprob( varargin )

global cvx___
cvx_global
tstart = tic;
if ~iscellstr( varargin ),
    error( 'Arguments must be strings.' );
end

%
% Clear out any old problems left at this depth. These will be here due to
% an error while constructing a CVX model, or due to the user deciding to
% start over when constructing a model
%

st = dbstack;
depth = length( st ) - 2;
if length(st) <= 2,
    name = '';
else
    name = st(3).name;
end
if ~isempty( cvx___.problems ),
    ndx = find( [ cvx___.problems.depth ] >= depth );
    if ~isempty( ndx ),
        temp = cvx___.problems(ndx(1));
        if temp.depth == depth && ( ~isempty(temp.objective) || ~isempty(temp.variables) || ~isempty(temp.duals) || nnz(temp.t_variable) > 1 );
            warning( 'CVX:Empty', 'A non-empty cvx problem already exists in this scope.\n   It is being overwritten.', 1 ); %#ok
        end
        pop( temp.self, 'reset' );
    end
end

%
% Grab the latest defaults to place in the new problem
%

if ~isempty( cvx___.problems ),
    nprec  = cvx___.problems( end ).precision;
    npflag = cvx___.problems( end ).precflag;
    nrprec = cvx___.problems( end ).rat_growth;
    nsolv  = cvx___.problems( end ).solver;
    nquiet = cvx___.problems( end ).quiet;
else
    nprec  = cvx___.precision;
    npflag = cvx___.precflag;
    nrprec = cvx___.rat_growth;
    selected = cvx___.solvers.selected;
    if isfield( cvx___.solvers.list, 'settings'  ),
        nsolv  = struct( 'index', selected, 'settings', cvx___.solvers.list(selected).settings );
    else
        nsolv = struct( 'index', selected, 'settings', [] );
    end
    nquiet = cvx___.quiet;
end

%
% Construct the object
%

z = class( struct( 'index_', length( cvx___.problems ) + 1 ), 'cvxprob', cvxobj );
temp = struct( ...
    'name',          name,   ...
    'complete',      true,   ...
    'sdp',           false,  ...
    'gp',            false,  ...
    'separable',     false,  ...
    'locked',        false,  ...
    'precision',     nprec,  ...
    'precflag',      npflag, ...
    'solver',        nsolv,  ...
    'quiet',         nquiet, ... 
    'cputime',       cputime, ...
    'tictime',       tstart, ...
    'rat_growth',    nrprec, ...
    't_variable',    logical( sparse( length( cvx___.reserved ), 1 ) ), ...
    'n_equality',    length(cvx___.equalities), ...
    'n_linform',     length(cvx___.linforms), ...
    'n_uniform',     length(cvx___.uniforms), ...
    'variables',     [],         ...
    'duals',         [],         ...
    'dvars',         [],         ...
    'direction',     '',         ...
    'geometric',     [],         ...
    'objective',     [],         ...
    'status',        'unsolved', ...
    'result',        [],         ...
    'bound',         [],         ...
    'iters',         Inf,        ...
    'tol',           Inf,        ...
    'depth',         depth,      ...
    'self',          z );
temp.t_variable( 1 ) = true;

%
% Process the argument strings
%

for k = 1 : nargin,
    mode = varargin{k};
    switch lower( mode ),
        case 'quiet',
            temp.quiet = true;
        case 'set',
            temp.complete  = false;
            temp.direction = 'find';
        case 'sdp',
            if temp.gp,
                error( 'The GP and SDP modifiers cannot be used together.' );
            end
            temp.sdp = true;
        case 'gp',
            if temp.sdp,
                error( 'The GP and SDP modifiers cannot be used together.' );
            end
            temp.gp = true;
            if cvx___.expert == 0,
                cvx___.expert = -1;
            end
        case 'separable',
            temp.separable = true;
        otherwise,
            error( 'Invalid CVX problem modifier: %s', mode );
    end
end

%
% Add the problem to the stack
%

if isempty( cvx___.problems ),
    cvx___.problems = temp;
    cvx_setpath(1);
    if cvx___.profile,
        profile resume
    end
else
    cvx___.problems( end + 1 ) = temp;
end

% Copyright 2005-2016 CVX Research, Inc.
% See the file LICENSE.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.
