function op = smooth_logLLogistic(y)
% SMOOTH_LOGLLOGISTIC Log-likelihood function of a logistic: sum_i( y_i mu_i - log( 1+exp(mu_i) ) )
%   OP = SMOOTH_LOGLLOGISTIC( Y )
%   returns a function that computes the log-likelihood function
%   in a standard logistic regression model with independent entries. There
%   are two classes y_i = 0 and y_i = 1 with 
% 
%   prob(y_i = 1) = exp(mu_i)/(1 + exp(mu_i)
% 
%   so that the log-likelihood is given by 
%
%       log-likelihood(mu) = sum_i ( y_i mu_i - log(1+ exp(mu_i)) ) 
%
%   where mu is the parameter of the distribution (this is unknown,
%   so it is the variable), and Y is a vector of observations.

error(nargchk(1,1,nargin));
op = tfocs_smooth( @smooth_logLlogistic_impl);

function [ v, g ] = smooth_logLlogistic_impl( mu )

  if length(mu) == 1, 
      mu = mu * ones(size(y));
  elseif size(mu) ~= size(y),
      error('Parameters and data must be of the same size'),
  end
  
  aux = 1 + exp(-abs(mu));
  v = tfocs_dot(y-1,mu.*(mu > 0)) ...
         + tfocs_dot(y,mu.*(mu < 0)) ...
              - tfocs_dot(ones(size(y)), log(aux));
  if nargout > 1,
      g = y - ((mu > 0) + (mu <= 0).*exp(mu))./aux;
  end
end

end
  
% TFOCS v1.3 by Stephen Becker, Emmanuel Candes, and Michael Grant.
% Copyright 2013 California Institute of Technology and CVX Research.
% See the file LICENSE for full license information.
