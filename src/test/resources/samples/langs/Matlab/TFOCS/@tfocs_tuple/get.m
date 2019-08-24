function y = get( x, ndxs )
if nargin == 0,
    y = x.value_;
elseif numel(ndxs) == 1,
    y = x.value_{ndxs};
else
    y = x.value_(ndxs);
end

% TFOCS v1.3 by Stephen Becker, Emmanuel Candes, and Michael Grant.
% Copyright 2013 California Institute of Technology and CVX Research.
% See the file LICENSE for full license information.
