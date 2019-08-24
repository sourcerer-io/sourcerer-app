function timers = cvx_toc
 
%CVX_TOC Returns the current timing information.
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
if isempty( cvx___ ),
    error( 'CVX has not yet been used (or the global workspace has been cleared).' );
end
tstart = tic;
timers = double(cvx___.timers);
dbltim = isa( timers, 'double' );
if dbltim,
    tstart = double(tstart);
end
timers(1) = tstart - timers(1);
if isempty(cvx___.increment),
    switch computer,
        case { 'MACI', 'MACI64' },
            cvx___.increment = 1e9;
        otherwise,
            t1 = tic; pause(0.25); t2 = tic; t3 = toc(t1); t4=toc(t2);
            if dbltim,
                cvx___.increment = (double(t2)-double(t1))/(double(t3)-0.5*double(t4));
            else
                two = uint64(2);
                cvx___.increment = double( two * ( t2 - t1 ) ) / ( two * t3 - t4 );
            end
    end
end
timers = [ timers(1), timers(1:3) - timers(2:4), timers(4) ];
timers = timers / cvx___.increment;
if nargout == 0,
    fprintf( 'Total time:      %g sec\n', timers(1) );
    fprintf( 'Outside of CVX:  %g sec\n', timers(2) );
    fprintf( 'Model building:  %g sec\n', timers(3) );
    fprintf( 'Presolving:      %g sec\n', timers(4) );
    fprintf( 'Solving:         %g sec\n', timers(5) );
    clear timers
end
    
% Copyright 2005-2016 CVX Research, Inc.
% See the file LICENSE.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.
