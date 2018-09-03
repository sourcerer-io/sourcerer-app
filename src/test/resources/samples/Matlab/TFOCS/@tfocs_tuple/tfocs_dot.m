function v = tfocs_dot( x, y )

% TFOCS_DOT    Dot products.

if isempty( x ) || isempty( y ),
	v = 0;
else
	v = sum( cellfun( @tfocs_dot, x.value_, y.value_ ) );
end

% TFOCS v1.3 by Stephen Becker, Emmanuel Candes, and Michael Grant.
% Copyright 2013 California Institute of Technology and CVX Research.
% See the file LICENSE for full license information.
