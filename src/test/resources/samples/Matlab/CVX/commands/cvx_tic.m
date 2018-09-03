function cvx_tic
 
%CVX_TIC Resets the CVX timing functionality.
%
%   CVX collects the following timing information:
%   --- Elapsed time since CVX_TIC was last called. If CVX_TIC was never
%       called, this measures the time since CVX was first initialized.
%   --- Elapsed time spent between top-level CVX_BEGIN and CVX_END comamnds
%   --- Elapsed time spent within the top-level CVX_END itself. This
%       includes final problem extraction, presolving, and solving.
%   --- Elapsed time spent calling the numerical solver.
%   To retrieve the current totals for these numbers, type CVX_TOC.
%   CVX_TIC resets these numbers to zero.

global cvx___
cvx_global
if ~isempty( cvx___.problems ),
    error( 'CVX_TIC can only be called when no models are in construction.' );
end
cvx___.timers(1) = tic;
cvx___.timers(2:4) = 0;

% Copyright 2005-2016 CVX Research, Inc.
% See the file LICENSE.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.
