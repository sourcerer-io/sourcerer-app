function x = abs( x )

% ABS   Absolute value.

n = numel( x.value_ );
for k = 1 : n,
    x.value_{k} = abs( x.value_{k} );
end

% TFOCS v1.3 by Stephen Becker, Emmanuel Candes, and Michael Grant.
% Copyright 2013 California Institute of Technology and CVX Research.
% See the file LICENSE for full license information.
