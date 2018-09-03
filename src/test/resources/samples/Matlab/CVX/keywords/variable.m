function varargout = variable( varargin )

%VARIABLE Declares a single CVX variable with optional matrix structure.
%   VARIABLE x
%   where x is a valid MATLAB variable nm, declares a scalar
%   variable for the current cvx problem. A variable with that
%   name is added to the problem, and a cvx object with that
%   name is created in the current workspace. An error is
%   generated if a cvx problem isn't in the current workspace.
%
%   VARIABLE x(n1,n2,...,nk)
%   declares a vector, matrix, or array variable with dimensions
%   n1, n2, ..., nk, each of which must be positive integers.
%
%   VARIABLE x(n1,n2,...,nk) mod1 mod2 mod3 ... modp
%   declares a vector, matrix, or array with structure. The
%   modifiers mod1, mod2, ... can each be one of the following:
%       complex   symmetric   skew-symmetric   hermitian
%       skew-hermitian   toeplitz   hankel   upper-hankel
%       lower-triangular   upper-triangular   tridiagonal
%       diagonal   lower-bidiagonal   upper-bidiagonal
%   Appropriate combinations of these modifiers can be chosen
%   as well. All except "complex" require that the matrix be
%   square. If an N-D (N>2) array is specified, then the matrix
%   structure is applied to each 2-D "slice" of the array.
%
%   Examples:
%      variable x(100,100) symmetric tridiagonal
%      variable z(10,10,10)
%      variable y complex
%
%   See also VARIABLES, DUAL, DUALS.

global cvx___
prob = evalin( 'caller', 'cvx_problem', '[]' );
if ~isa( prob, 'cvxprob' ),
    error( 'No CVX model exists in this scope.' );
elseif isempty( cvx___.problems ),
    error( 'Internal CVX data corruption. Please CLEAR ALL and rebuild your model.' );
end
pstr = cvx___.problems( end );
if pstr.self ~= prob,
    error( 'Internal CVX data corruption. Please CLEAR ALL and rebuild your model.' );
end

%
% Parse the text
%

name = cell( 1, nargin );
args = cell( 1, nargin );
toks = regexp( varargin, '^([a-zA-Z]\w*)(\(.*\))?$', 'tokens' );
for k = 1 : nargin,
    tok = toks{k};
    if isempty( tok ),
        if k == 1, type = 'Variable'; else type = 'Structure'; end
        error( sprintf('CVX:Invalid%sSpec',type), 'Invalid %s specification: %s', lower(type), varargin{k} );
    end
    tok = tok{1};
    name{k} = tok{1};
    if length(tok) < 2 || isempty( tok{2} ),
        args{k} = {};
    else
        try
            args{k} = evalin( 'caller', [ '{', tok{2}(2:end-1), '};' ] );
        catch exc
            error( exc.identifier, exc.message );
        end
    end
end

%
% Get the variable name and size
%

xname = name{1};
if ~isvarname( xname ),
    error( 'CVX:InvalidVariableSpec', 'Invalid variable name: %s', xname );
elseif xname(end) == '_',
    error( 'CVX:InvalidVariableSpec', 'Invalid variable name: %s\n   Variables ending in underscores are reserved for internal use.', xname );
elseif isfield( cvx___.reswords, xname ),
    if cvx___.reswords.(xname) == 'S',
        error( 'CVX:InvalidVariableSpec', 'Invalid variable name: %s\n   This is a reserved word in CVX.\n   Trying to declare a structured matrix? Use the VARIABLE keyword instead.', xname );
    else
        error( 'CVX:InvalidVariableSpec', 'Invalid variable name: %s\n   This is a reserved word in CVX.', xname );
    end
elseif isfield( pstr.variables, xname ),
    error( 'CVX:InvalidVariableSpec', 'Duplicate variable name: %s', xname );
end
switch evalin('caller',['exist(''',xname,''')']),
    case {0,1},
    case 5,
        error( 'CVX:InvalidVariableSpec', 'Variable name "%s" is the name of a built-in MATLAB function.\nPlease choose a different name.', xname );
    case 8,
        error( 'CVX:InvalidVariableSpec', 'Variable name "%s" is the name of an existing MATLAB class.\nPlease choose a different name.', xname );
    otherwise,
        mpath = which( xname );
        if ~isempty( mpath ),
            if strncmp( mpath, matlabroot, length(matlabroot) ),
                error( 'CVX:InvalidVariableSpec', 'Variable name "%s" is the name of an existing MATLAB function or directory:\n    %s\nPlease choose a different name.', xname, mpath );
            elseif strncmp( mpath, cvx___.where, length(cvx___.where) ),
                error( 'CVX:InvalidVariableSpec', 'Variable name "%s" matches the name of a CVX function or directory:\n    %s\nPlease choose a different name.', xname, mpath );
            else
                warning( 'Variable name "%s" matches the name of an function or directory:\n    %s\nThis may cause unintended behavior with CVX models.\nPlease consider moving this file or choosing a different variable name.', xname, mpath );
            end
        end
end
try
    xsize = [ args{1}{:} ];
catch exc
    error( exc.identifier, exc.message );
end
if ~isempty( xsize ),
    [ temp, xsize ] = cvx_check_dimlist( xsize, true );
    if ~temp,
        error( 'CVX:InvalidDimensions', 'Invalid dimension list: %s\n   Dimension list must be a vector of finite nonnegative integers.', varargin{1} );
    end
end

%
% Parse the structure
%

isepi  = false;
ishypo = false;
isnneg = false;
issemi = false;
itype  = '';
if nargin > 1,
    try
        [ str, itypes ] = cvx_create_structure( varargin, name, args );
    catch exc
        error( exc.identifier, exc.message );
    end
    n_itypes = 0;
    for k = 1 : length( itypes ),
        strs = itypes{k};
        switch strs,
            case 'epigraph_',    isepi  = true;
            case 'hypograph_',   ishypo = true;
            case 'integer',      n_itypes = n_itypes + 1; itype = 'i_integer';
            case 'binary',       n_itypes = n_itypes + 1; itype = 'i_binary';
            case 'nonnegative',  isnneg = true;
            case 'semidefinite', issemi = true;
        end
    end
    if isepi && ishypo,
        error( 'EPIGRAPH and HYPOGRAPH keywords cannot be used simultaneously.' );
    end
    if n_itypes,
        if pstr.gp,
            error( 'Integer variables cannot be used in geometric programs.' );
        elseif isepi || ishypo,
            error( 'Integer variables cannot be used as epigraphs or hypograph variables.' );
        elseif issemi,
            error( 'Integer variables cannot also be declared semidefinite.' );
        elseif n_itypes > 1,
            error( 'At most one integer keyword may be specified.' );
        end
    end
else
    str = [];
end

%
% Create the variables
%

try
    v = newvar( prob, xname, xsize, str, pstr.gp );
catch exc
    error( exc.message );
end
if isepi || ishypo,
    if pstr.gp, vv = log( v ); else vv = v; end
    if isepi, dir = 'epigraph'; else dir = 'hypograph'; end
    cvx___.problems( end ).objective = vv;
    cvx___.problems( end ).direction = dir;
    cvx___.problems( end ).geometric = pstr.gp;
end
if itype,
    [ tx, dummy ] = find( cvx_basis( v ) ); %#ok
    newnonl( prob, itype, tx(:)' );
    cvx___.canslack( tx ) = false;
end
if issemi,
    [ dummy, issemi ] = newcnstr( prob, v, 0, '>=', true ); %#ok
    if ~issemi, isnneg = false; end
end
if isnneg && ~pstr.gp && ~strcmp( itype, 'i_binary' ),
    newcnstr( prob, v, 0, '>=', false );
end
if nargout > 0,
    varargout{1} = v;
else
    assignin( 'caller', xname, v );
end

% Copyright 2005-2016 CVX Research, Inc.
% See the file LICENSE.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.
