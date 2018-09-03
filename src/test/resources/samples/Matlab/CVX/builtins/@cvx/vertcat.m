function y = vertcat( varargin )

%   Disciplined convex/geometric programming information for VERTCAT:
%      VERTCAT imposes no convexity restrictions on its arguments.

y = cat( 1, varargin{:} );

% Copyright 2005-2016 CVX Research, Inc.
% See the file LICENSE.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.
