function z = newdual( prob, name, reps )
narginchk(2,3);

%
% Check problem
%

if ~isa( prob, 'cvxprob' ),
    error( 'First argument must be a cvxprob object.' );
end
global cvx___
p = prob.index_;
vars = cvx___.problems( p ).duals;

%
% Check name
%

if isempty( name ),
    error( 'Anonymous dual variables are not allowed.' );
elseif ischar( name ),
    if ~isempty( name ),
        if size( name, 1 ) ~= 1,
            error( 'Second argument must be a string or a subscript structure array.' );
        elseif ~isvarname( name ),
            error( 'Invalid dual variable name: %s', name );
        elseif isfield( vars, name ),
            error( 'Dual variable name conflict: %s', name );
        elseif isfield( cvx___.problems( p ).variables,name ),
            error( 'Primal/dual variable name conflict: %s', name );
        end
    end
end

%
% Check repetition
%

if nargin < 3,
    reps = [];
elseif ~isempty( reps ),
    [ temp, reps ] = cvx_check_dimlist( reps, true );
    if ~temp,
        error( 'Third argument must be a dimension list.' );
    end
end

%
% Add the variable to the problem
%

nstr = struct( 'type', '.', 'subs', name );
if ~isempty( reps ),
    y = cell( reps );
    [ y{:} ] = deal( cvx );
    z = cell( reps );
    q = cell( reps );
    ndxs = cell( 1, length( reps ) - ( reps(end) == 1 ) );
    [ ndxs{:} ] = ind2sub( reps, 1 : prod( reps ) );
    ndxs = vertcat( ndxs{:} );
    nstr(2).type = '{}';
    for k = 1 : prod( reps ),
        nstr(2).subs = sprintf( '%d,', ndxs(:,k) );
        nstr(2).subs = eval( [ '{', nstr(2).subs(1:end-1), '}' ] );
        z{k} = cvxdual( p, nstr );
    end
else
    y = [];
    z = cvxdual( p, nstr );
end
vars = cvx___.problems( p ).dvars;
vars = builtin( 'subsasgn', vars, nstr(1), z );
cvx___.problems( p ).dvars = vars;
vars = cvx___.problems( p ).duals;
vars = builtin( 'subsasgn', vars, nstr(1), y );
cvx___.problems( p ).duals = vars;
cvx___.x = [];
cvx___.y = [];

% Copyright 2005-2016 CVX Research, Inc.
% See the file LICENSE.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.
