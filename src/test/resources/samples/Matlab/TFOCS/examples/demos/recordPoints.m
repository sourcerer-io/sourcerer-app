function er = recordPoints( x )

persistent history

if nargin == 0
    er = history;
    history = [];
    return;
end

history = [history, x ];
er  = 0;

% TFOCS v1.3 by Stephen Becker, Emmanuel Candes, and Michael Grant.
% Copyright 2013 California Institute of Technology and CVX Research.
% See the file LICENSE for full license information.

