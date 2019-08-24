function cvx_optpnt = norm_ball( sz, varargin ) %#ok

%NORM_BALL   Norm ball.
%   NORM_BALL( sz, ... ) returns a variable of size sz, say 'x', that is
%   constrained to satisfy NORM( x, ... ) <= 1. Any syntactically valid
%   and _convex_ use of the NORM() function has a direct analog in
%   NORM_BALL. The convex requirement specifically excludes, then, all
%   instances of NORM( x, p ) where p < 1.
%
%   See NORM for more detaills.
%
%   Disciplined convex programming information:
%       NORM_BALL is a cvx set specification. See the user guide for
%       details on how to use sets.

narginchk(1,Inf);
[ temp, sz ] = cvx_check_dimlist( sz, false );
if ~temp,
    error( 'First argument must be a valid dimension list.' );
elseif length( sz ) > 2,
    error( 'N-D arrays not supported.' );
end

cvx_begin set
    variable x( sz )
    norm( x, varargin{:} ) <= 1; %#ok
cvx_end

% Copyright 2005-2016 CVX Research, Inc. 
% See the file LICENSE.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.
