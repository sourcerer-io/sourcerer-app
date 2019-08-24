function v = tfocs_normsq( x )

% TFOCS_NORMSQ    Squared norm. By default, TFOCS_NORMSQ(X) is equal
%                 to TFOCS_NORMSQ(X,X), and this numerical equivalence
%                 must be preserved. However, an object may overload
%                 TFOCS_NORMSQ to compute its value more efficiently.

v = sum( cellfun( @tfocs_normsq, x.value_ ) );

% TFOCS v1.3 by Stephen Becker, Emmanuel Candes, and Michael Grant.
% Copyright 2013 California Institute of Technology and CVX Research.
% See the file LICENSE for full license information.
