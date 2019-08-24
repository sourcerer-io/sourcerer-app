function out = plotNow( x, pause_t , plotFcn )
% out = plotNow( x, pause_t )
%   helper function for plotting a movie during
%   the TFOCS iterations.
% Call this function with no inputs in order
%   to reset it.
% Call this with a matrix and it will plot it using "imshow".
%
% The input "pause_t" controls how long to pause
%   (this is useful when solving a small problem that would
%    otherwise progress too fast between iterates).
% 
% out = plotNow( x, pause_t, plotFcn )
%   will plot "x" using "plotFcn" instead of the default "imshow"

persistent counter
if isempty(counter)
    counter = 0;
end
if nargin == 0
    counter = 0;
    return;
end
counter = counter + 1;

if nargin < 3 || isempty(plotFcn), plotFcn = @(x) imshow(x); end

plotFcn(x);
title(sprintf('Iteration %2d',counter));
drawnow

if nargin > 1 && ~isempty(pause_t)
    pause(pause_t);
end

out = 0;

% TFOCS v1.3 by Stephen Becker, Emmanuel Candes, and Michael Grant.
% Copyright 2013 California Institute of Technology and CVX Research.
% See the file LICENSE for full license information.
