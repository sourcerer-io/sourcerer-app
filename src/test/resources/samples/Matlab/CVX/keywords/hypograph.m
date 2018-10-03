function hypograph( varargin )

%HYPOGRAPH Declares a hypograph variable.
%   HYPOGRAPH VARIABLE x
%   where x is a valid MATLAB variable name, declares a scalar
%   variable for the current cvx problem, and specifies it as
%   the objective of a maximization. There is no need to declare
%   a separate MAXIMIZE command.
%
%   This keyword should be used only when attempting to
%   create a new function for the CVX library. Suppose you have a
%   function F(X) whose hypograph {(X,Y)}{F(X)>=Y} can be
%   described as a CVX feasibiliy problem. Then declaring Y
%   as an EPIGRAPH turns the model into one that computes the
%   value of the function itself, maximizing over Y.
%
%   Other uses of this keyword are NOT supported and can lead
%   to numerical errors.
%
%   HYPOGRAPH VARIABLE x(n1,n2,...,nk)
%   declares a vector, matrix, or array hypograph variable with
%   dimensions n1, n2, ..., nk, each of which must be positive
%   integers.
%
%   Structure modifiers such as "symmetric", "toeplitz", etc.
%   are permitted with hypograph variables.
%
%   Examples:
%      hypograph variable x
%      hypograph variable x(100)
%
%   See also VARIABLE, EPIGRAPH.

if nargin < 2,
    error( 'Incorrect syntax for HYPOGRAPH VARIABLE. Type HELP HYPOGRAPH for details.' );
elseif ~iscellstr( varargin ),
    error( 'All arguments must be strings.' );
elseif ~strcmp( varargin{1}, 'variable' ),
    error( 'Incorrect syntax for HYPOGRAPH VARIABLE. Type HELP HYPOGRAPH for details.' );
end
evalin( 'caller', sprintf( '%s ', 'variable', varargin{2:end}, ' hypograph_' ) );

% Copyright 2005-2016 CVX Research, Inc.
% See the file LICENSE.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.
