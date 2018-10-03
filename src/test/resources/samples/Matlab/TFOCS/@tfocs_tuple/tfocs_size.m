function v = tfocs_size( x )

v = { @tfocs_tuple, cellfun( @size, x.value_, 'UniformOutput', false ) };

% TFOCS v1.3 by Stephen Becker, Emmanuel Candes, and Michael Grant.
% Copyright 2013 California Institute of Technology and CVX Research.
% See the file LICENSE for full license information.
