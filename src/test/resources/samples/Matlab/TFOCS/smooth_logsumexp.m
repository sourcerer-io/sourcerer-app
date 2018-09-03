function op = smooth_logsumexp(sigma)
% SMOOTH_LOGSUMEXP The function log(sum(exp(x)))
%   returns a smooth function to calculate
%   log( sum( exp(x) ) )
%
% SMOOTH_LOGSUMEXP( SIGMA ) is a scaled version
%   that calclates sigma*log(sum(exp(x/sigma)), for sigma > 0.
%   As sigma --> 0, this becomes a good approximation
%   of max(x).
%   The Lipschitz constant of the gradient is 1/sigma.
%   By default, sigma = 1.
%
% For a fancier version (with offsets),
% see also smooth_logLLogistic.m

if nargin < 1 || isempty(sigma), sigma = 1; end
op = @(x)smooth_logsumexp_impl(x,sigma);

function [ v, g ] = smooth_logsumexp_impl( x, sigma )

% Even for moderate values of x/sigma, exp(x/sigma)
%   will overflow before we have a chance to take
%   its logarithm. So we subtract off the max value
%   and treat it separately:

c    = max(x);
expx = exp((x-c)/sigma);
sum_expx = sum(expx(:));
v = sigma*log(sum_expx) + c;

if nargout > 1,
    g = expx ./ sum_expx;
    % (the factor of e^{-c} cancels from both the numerator
    %  and denominator)
end

% TFOCS v1.3 by Stephen Becker, Emmanuel Candes, and Michael Grant.
% Copyright 2013 California Institute of Technology and CVX Research.
% See the file LICENSE for full license information.
