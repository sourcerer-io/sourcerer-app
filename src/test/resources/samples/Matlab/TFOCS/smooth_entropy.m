function op = smooth_entropy()
%SMOOTH_ENTROPY The entropy function -sum( x_i log(x_i) )
op = @smooth_entropy_impl;

function [ v, g ] = smooth_entropy_impl( x )
if any( x < 0 ),
    v = -Inf;
    if nargout > 1,
        g = NaN * ones(size(x));
    end
else
    logx = log(max(x,realmin));
    v = - tfocs_dot( x, logx );
    if nargout > 1,
        g = - logx - 1;
    end
end

% TFOCS v1.3 by Stephen Becker, Emmanuel Candes, and Michael Grant.
% Copyright 2013 California Institute of Technology and CVX Research.
% See the file LICENSE for full license information.
