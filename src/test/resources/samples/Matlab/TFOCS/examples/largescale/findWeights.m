function w = findWeights( coeff, p )
% weights = findWeights( coefficients, p )
%   creates a nice vector of reweighting coefficients
%   for use with re-weighted l1.
%   The regularization parameter is chosen to be the coefficient
%   that accounts for p-percent (0<p<1) of the total power.

error(nargchk(2,2,nargin));
if ~isscalar(p) || p < 0 || p > 1
    error('p must be a scalar between [0,1]' );
end

coeff     = abs(coeff);
coeffSort = sort(coeff,'descend');
c         = cumsum( coeffSort.^2 );
indx      = find( c/c(end) > p, 1, 'first' );
if ~isempty(indx)
    delta   = coeffSort( indx );
else
    delta   = 1e-15;
end

w   = delta./( coeff + delta );
% TFOCS v1.3 by Stephen Becker, Emmanuel Candes, and Michael Grant.
% Copyright 2013 California Institute of Technology and CVX Research.
% See the file LICENSE for full license information.
