function op = smooth_logLPoisson(x)
% SMOOTH_LOGLPOISSON Log-likelihood of a Poisson: sum_i (-lambda_i + x_i * log( lambda_i) )
%   OP = SMOOTH_LOGLPOISSON( X )
%   returns a function that computes the log-likelihood function
%   of independent Poisson random variables with parameters lambda_i:
%
%       log-likelihood(lambda) = sum_i ( -lambda_i + x_i * log( lambda_i) )
%
%   where LAMBDA is the parameter of the distribution (this is unknown,
%    so it is the variable), and X is a vector of observations.
%
%   Note: the constant term in the log-likelihood is omitted.

error(nargchk(1,1,nargin));
op = tfocs_smooth( @smooth_llPoisson_impl );

function [ v, g ] = smooth_llPoisson_impl( lambda )

  if length(lambda) == 1, 
      lambda = lambda * ones(size(x));
  elseif size(lambda) ~= size(x),
      error('Parameters and data must be of the same size'),
  end
  
  if any( lambda < 0 ),
      v = -Inf;
      if nargout > 1,
          g = NaN * ones(size(x));
      end
  else
      loglambda = log(max(lambda,realmin));
      v = - tfocs_dot(lambda, ones(size(x))) + tfocs_dot( x, loglambda);
      if nargout > 1,
          g = -1 + x./lambda;
      end
  end
end

end

% TFOCS v1.3 by Stephen Becker, Emmanuel Candes, and Michael Grant.
% Copyright 2013 California Institute of Technology and CVX Research.
% See the file LICENSE for full license information.
