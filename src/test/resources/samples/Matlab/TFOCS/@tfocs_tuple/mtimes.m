function y = mtimes( x, y )

% MTIMES   Multiplication. TFOCS_TUPLE objects may only be left-multiplied
%          by real scalars.

for k = 1 : numel( y.value_ ),
    y.value_{k} = x * y.value_{k};
end

% TFOCS v1.3 by Stephen Becker, Emmanuel Candes, and Michael Grant.
% Copyright 2013 California Institute of Technology and CVX Research.
% See the file LICENSE for full license information.
