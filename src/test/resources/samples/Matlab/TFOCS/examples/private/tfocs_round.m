function y = tfocs_round(x)
if iscell( x ),
    y = cellfun( @tfocs_round, x, 'UniformOutput', false );
else
    y = round( x );
end

% TFOCS v1.3 by Stephen Becker, Emmanuel Candes, and Michael Grant.
% Copyright 2013 California Institute of Technology and CVX Research.
% See the file LICENSE for full license information.
