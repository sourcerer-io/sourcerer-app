function variables( varargin )

%VARIABLES Declares one or more CVX variables.
%   VARIABLES x1 x2 x3 ..., where x1, x2, x3, etc. are valid
%   variable names, declares multiple cvx variables. It is
%   exactly equivalent to issuing a separate VARIABLE command
%   for each x1, x2, x3, ...
%        
%   VARIABLES allows the declaration of vector, matrix, and
%   array variables. However, unlike VARIABLE, structure modifiers
%   such as "symmetric", "toeplitz", etc. are NOT permitted. Thus
%   VARIABLES cannot be used with variables with structure.
%
%   Examples:
%      variables x y z;
%      variables x(100) y z(100,10);
%
%   See also VARIABLE, DUAL, DUALS.

if nargin < 1,
    error( 'Incorrect syntax for VARIABLES. Type HELP VARIABLES for details.' );
elseif ~iscellstr( varargin ),
    error( 'All arguments must be strings.' );
end
for k = 1 : nargin,
	evalin( 'caller', [ 'variable ', varargin{k} ] );
end

% Copyright 2005-2016 CVX Research, Inc. 
% See the file LICENSE.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.
