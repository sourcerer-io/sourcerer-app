function varargout = solver_apply( ndxs, func, varargin )
global tfocs_count___

%SOLVER_APPLY	Internal TFOCS routine.
%	A wrapper function used to facilitate the counting of function calls, and
%   to standardize the number of output arguments for the algorithms.

[ varargout{1:max(nargout,1)} ] = func( varargin{:} );
tfocs_count___(ndxs) = tfocs_count___(ndxs) + 1;

% TFOCS v1.3 by Stephen Becker, Emmanuel Candes, and Michael Grant.
% Copyright 2013 California Institute of Technology and CVX Research.
% See the file LICENSE for full license information.
