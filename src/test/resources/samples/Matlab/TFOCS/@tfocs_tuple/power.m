function x = power( x, y )

% POWER     Matrix power, z = x.^y

if isa(y,'tfocs_tuple')
	x.value_ = cellfun( @power, x.value_, y.value_, 'UniformOutput', false );
elseif isscalar(y)
	x.value_ = cellfun( @power, x.value_, {y}, 'UniformOutput', false );
else 
	x.value_ = cellfun( @power, x.value_, {y}, 'UniformOutput', false );
end

% TFOCS v1.3 by Stephen Becker, Emmanuel Candes, and Michael Grant.
% Copyright 2013 California Institute of Technology and CVX Research.
% See the file LICENSE for full license information.
