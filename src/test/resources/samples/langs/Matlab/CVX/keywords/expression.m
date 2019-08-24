function varargout = expression( nm, varargin )

%EXPRESSION Declares a single CVX object for storing subexpressions.
%   EXPRESSION x
%   where x is a valid MATLAB variable nm, declares a scalar expression 
%   holder for the current cvx model. Like a variable, an expression holder
%   can be used in constraints and objectives, according to the DCP ruleset.
%   However, unlike a variable, an expression holder is initialized to
%   zero, because the intent is for it to hold intermediate computations.
%
%   EXPRESSION x(n1,n2,...,nk)
%   declares a vector, matrix, or array expression holder with dimensions
%   n1, n2, ..., nk, each of which must be nonnegative integers. The value
%   of the expression holder is initialized to zero.
%
%   Examples:
%      variable x y
%      expression z
%      z = 2 * x - y;
%
%   See also EXPRESSIONS.

global cvx___
prob = evalin( 'caller', 'cvx_problem', '[]' );
if ~isa( prob, 'cvxprob' ),
    error( 'No CVX model exists in this scope.' );
elseif isempty( cvx___.problems ) || cvx___.problems( end ).self ~= prob,
    error( 'Internal CVX data corruption. Please CLEAR ALL and rebuild your model.' );
elseif nargin > 1,
    error( 'Too many input arguments.\nTrying to declare multiple expression holders? Use the EXPRESSIONS keyword instead.', 1 ); %#ok
end

%
% Step 1: separate the name from the parenthetical, verify the name
%

toks = regexp( nm, '^\s*([a-zA-Z]\w*)\s*(\(.*\))?\s*$', 'tokens' );
if isempty( toks ),
    error( 'Invalid variable specification: %s', nm );
end
toks = toks{1};
x.name = toks{1};
x.size = toks{2};
if x.name(end) == '_',
    error( 'Invalid expression specification: %s\n   Names ending in underscores are reserved for internal use.', nm );
end

%
% Step 2: Parse the size. In effect, all we do here is surround what is
% replace the surrounding parentheses with square braces and evaluate. All
% that matters is the result is a valid size vector. In particular, it
% need to be a simple comma-delimited list.
%

if isempty( x.size ),
	x.size = [1,1];
else
    try
        x.size = evalin( 'caller', [ '[', x.size(2:end-1), '];' ] );
    catch exc
        error( exc.identifier, exc.message );
    end
    [ temp, x.size ] = cvx_check_dimlist( x.size, true );
    if ~temp,
        error( 'Invalid expression specification: %s\n   Dimension list must be a vector of finite nonnegative integers.', nm );
    end
end

%
% Step 3. Initialize
%

v = cvx( x.size, [] );
if nargout > 0,
    varargout{1} = v;
else
    assignin( 'caller', x.name, v );
end

% Copyright 2005-2016 CVX Research, Inc.
% See the file LICENSE.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.
