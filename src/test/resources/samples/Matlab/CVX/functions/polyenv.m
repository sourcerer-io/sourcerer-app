function y = polyenv( varargin )

%POLYENV Evaluate the convex or concave envelope of a polynomial.
%   We have replaced this function with POLY_ENV to better match our
%   function naming conventions. Please start using it instead.

warning( 'CVX:Renamed', [ ...
    'The function "polyenv" has been renamed "poly_env". Please start using\n', ...
    'the new name. The old name will be removed in a future release.' ], 1 ); 
           
y = poly_env( varargin{:} );

% Copyright 2005-2016 CVX Research, Inc. 
% See the file LICENSE.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.
