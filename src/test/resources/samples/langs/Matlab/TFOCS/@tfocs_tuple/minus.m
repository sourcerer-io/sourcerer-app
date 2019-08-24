function x = minus( x, y )

% MINUS   Subtraction.

if isnumeric( x ) && isscalar( x ) && x == 0,
    x = -y;
elseif ~isnumeric( y ) || numel( y ) ~= 1 || y ~= 0
	x.value_ = cellfun( @minus, x.value_, y.value_, 'UniformOutput', false );
end

% TFOCS v1.3 by Stephen Becker, Emmanuel Candes, and Michael Grant.
% Copyright 2013 California Institute of Technology and CVX Research.
% See the file LICENSE for full license information.
