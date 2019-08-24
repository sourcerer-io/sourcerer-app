function cvx_begin( varargin )

%CVX_BEGIN    Starts a new CVX specification.
%   CVX_BEGIN marks the beginning of a new CVX model. Following this command
%   may be variable declarations, objective functions, and constraints, and
%   a CVX_END to mark the completion of the model.
%
%   If another model has already been created and is still in progress, then
%   CVX_BEGIN will issue a warning and clear the previous model.
%
%   CVX_BEGIN SDP marks the beginning of a semidefinite programming (SDP) model.
%   This command alters the interpretation of inequality constraints when used
%   with matrices, so that SDPs are easier to construct. Specifically, 
%   constraints of the form
%       X >= Y    X > Y    Y < X    Y <= X
%   where X and Y are matrices (i.e., not vectors or scalars), CVX will
%   interpret them all as LMIs, and convert them to
%        X - Y == semidefinite(size(X,1));
%   X and Y _must_ be square and identically sized---with one exception: 
%   X or Y may also be the scalar number zero, so that expressions such as
%   X >= 0 have the expected meaning.
%
%   CVX_BEGIN GP marks the beginning of a geometric programming (GP) model. This
%   command alters the definition of the VARIABLE keyword to create geometric
%   variables by default GP and SDP cannot be supplied simultaneously.
%
%   CVX_BEGIN SET can be used to mark the beginning of a set definition---a cvx
%   feasibility problem intended to describe a set for use in other models. See
%   the files in the cvx subdirectory sets/ for examples. The SET keyword can be
%   combined with SDP or GP to specify sets which use SDP or GP conventions;
%   for example, CVX_BEGIN SET SDP
%
%   CVX_BEGIN SEPARABLE gives permission for CVX to solve a multiobjective
%   problem simply by taking the sum of the objectives and solving the resulting
%   single-objective problem. As the name implies, this produces equivalent 
%   results only when the subproblems are separable. Behavior is undefined when
%   one or more of the subproblems is infeasible or unbounded. The keyword is
%   ignored for sets and incomplete specifications.

if ~iscellstr( varargin ), error( 'Arguments must be strings.' ); end
assignin( 'caller', 'cvx_problem', cvxprob( varargin{:} ) );

% Copyright 2005-2016 CVX Research, Inc. 
% See the file LICENSE.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.
