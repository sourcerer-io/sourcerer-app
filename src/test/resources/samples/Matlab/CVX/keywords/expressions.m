function expressions( varargin )

%EXPRESSIONS Declares one or more CVX expression holders.
%   EXPRESSIONS x1 x2 x3 ..., where x1, x2, x3, etc. are valid
%   variable names, declares multiple cvx expression holders. It is
%   exactly equivalent to issuing a separate EXPRESSION command
%   for each x1, x2, x3, ...
%        
%   EXPRESSIONS allows the declaration of vector, matrix, and
%   array variables. 
%
%   For more information about expression holders, see the help for 
%   EXPRESSION or the CVX user guide.
%
%   Examples:
%      expressions x y z
%
%   See also EXPRESSION.

if nargin < 1,
    error( 'Incorrect syntax for EXPRESSIONS. Type HELP EXPRESSIONS for details.' );
elseif ~iscellstr( varargin ),
    error( 'All arguments must be strings.' );
end
for k = 1 : nargin,
    evalin( 'caller', [ 'expression ', varargin{k} ] );
end

% Copyright 2005-2016 CVX Research, Inc. 
% See the file LICENSE.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.
