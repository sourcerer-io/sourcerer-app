function varargout = dual( varargin )

%DUAL Declares one or more dual variables.
%
%   DUAL VARIABLE x
%   where x is a valid MATLAB variable name, declares a dual variable
%   for the current cvx problem. A dual variable with that name is added
%   to the problem and a cvxdual object with that name is created in
%   the current worksapce. An error is generated if a cvx problem is not
%   in the current workspace.
%
%   Note that a dual variable initially has no size; i.e., SIZE(x) returns
%   [0,0]. This is because the size of a dual variable is determined by the
%   constraint to which it is attached. To attach a dual variable to a
%   constraint, use the colon notation as follows:
%
%      variable x(n)
%      dual variable z
%      A * x == b : z
%
%   In this example, the dual variable z is attached to the equality
%   constraint A * x == b. Assuming SIZE(A) = [m,n] and SIZE(B) = [m,1],
%   the size of z will be set at [m,1] by this operation.
%
%   DUAL VARIABLES x1 x2 ... xk
%   where x1, x2, ..., xk are valid MATLAB variable names, declares
%   multiple dual variables.
%
%   DUAL VARIABLE x{s1,s2,...,sk}
%   DUAL VARIABLES x1{s1,s2,...,sk} x2{...
%   creates a cell array of dual variables, of dimension [s1,s2,..,sk].
%   This is useful if you want to create a sequence of related constraints,
%   using a FOR loop for example, and assign a separate dual variable to
%   each one; for example:
%
%       variable x(n)
%       dual variables z{10}
%       for k = 1 : 10,
%           A(:,:,k) * x <= b(:,k) : z{k}
%       end
%
%   Assuming SIZE(A) = [m,n,10] and SIZE(B) = [m,10], this loop assigns
%   each of the dual variables z{k} to a constraint and sets their sizes
%   to [m,1]. Note that the elements of the dual variable cell array need
%   not end up the same size.
%
%   See also VARIABLE, VARIABLES.

if nargin < 2,
    error( 'Incorrect syntax for DUAL VARIABLE(S). Type HELP DUAL for details.' );
elseif nargout && nargout ~= length( varargin ) - 1,
    error( 'Incorrect number of output arguments.' );
elseif ~iscellstr( varargin ),
    error( 'All arguments must be strings.' );
end

global cvx___
prob = evalin( 'caller', 'cvx_problem', '[]' );
if ~isa( prob, 'cvxprob' ),
    error( 'No CVX model exists in this scope.' );
elseif isempty( cvx___.problems ) || cvx___.problems( end ).self ~= prob,
    error( 'Internal CVX data corruption. Please CLEAR ALL and rebuild your model.' );
end

if strcmp( varargin{1}, 'variable' ),
    if nargin > 2,
        error( 'Too many input arguments.\nTrying to declare multiple dual variables? Use the DUAL VARIABLES command instead.', 1 ); %#ok
    end
elseif ~strcmp( varargin{1}, 'variables' ),
    error( 'Incorrect syntax for DUAL VARIABLE(S). Type HELP DUAL for details.' );
end

for k = 2 : nargin,
    arg = varargin{k};
    toks = regexp( arg, '^\s*([a-zA-Z]\w*)\s*({.*})?\s*$', 'tokens' );
    if isempty( toks ),
        error( 'Invalid dual variable specification: %s', arg );
    end
    tok = toks{1};
    nam = tok{1};
    if length(tok) < 2,
        siz = {};
    else
        siz = tok{2};
    end
    if nam(end) == '_',
        error( 'Invalid dual variable specification: %s\n   Variables ending in underscores are reserved for internal use.', arg );
    end
    if ~isempty( siz ),
        try
            siz = evalin( 'caller', [ '[', siz(2:end-1), ']' ] );
        catch exc
            error( exc.identifier, 'Error attempting to determine size of: %s\n   %s', arg, exc.message );
        end
        [ temp, siz ] = cvx_check_dimlist( siz, true );
        if ~temp,
            error( 'Invalid dual variable specification: %s\n   Dimension list must be a vector of finite nonnegative integers.', arg );
        end
    end
    temp = newdual( prob, nam, siz );
    if nargout,
        varargout{k-1} = temp; %#ok
    end
    assignin( 'caller', nam, temp );
end

% Copyright 2005-2016 CVX Research, Inc.
% See the file LICENSE.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.
