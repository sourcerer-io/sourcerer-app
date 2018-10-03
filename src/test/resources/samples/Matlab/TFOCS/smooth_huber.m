function op = smooth_huber(tau,vector)

%SMOOTH_HUBER   Huber function generation.
%   FUNC = SMOOTH_QUAD( TAU ) returns a function handle that implements
%
%        FUNC(X) = sum_i 0.5 *( x_i.^2 )/tau               if |x| <= tau
%                = sum_i |x_i| - tau/2                     if |x| >  tau
%
%   All arguments are optional; the default value is tau = 1.
%   The Huber function has continuous gradient and is convex.
%
%   The function acts component-wise.  TAU may be either a scalar
%   or a vector/matrix of the same size as X
%
%   Does not support nonsmooth usage yet
%
%   FUNC = SMOOTH_QUAD( TAU, VECTOR )
%       is the default behavior if VECTOR is false or [],
%       and if VECTOR==true, then the output value FUNC
%       is a vector of the same size as X. The default behavior
%       would be recovered by taking the sum of FUNC.
%       Note: the gradient is the same in either case, so make sure
%        this is what you expect.
%
% Modified Jan 16 2015, input from Martin Andersen,
%   changed default VECTOR behavior, and also compatible with 
%   complex numbers

% Does not yet fully support tfocs_tuples

if nargin == 0,
    tau = 1;
end
% op = @(varargin) smooth_huber_impl(tau, varargin{:} ); % old method

if nargin < 2 || isempty(vector), vector = false; end

op = tfocs_smooth( @(x)smooth_huber_impl(vector,x) );


% function [ v, g ] = smooth_huber_impl(tau, x, t ) % old method
function [ v, g ] = smooth_huber_impl(vector,x)
  if nargin == 4,
      error( 'Proximity minimization not supported by this function.' );
  end
  if ~isscalar(tau) && ~size(tau) == size(x)
      error('smooth_huber: tau must be a scalar or the same size as the variable');
  end
  if any(tau <= 0)
      error('smooth_huber: tau must be positive')
  end
  smallSet    = ( abs(x) <= tau );
  v           = smallSet.*( 0.5*(abs(x).^2)./tau ) + (~smallSet).*( abs(x) - tau/2) ;
  if ~vector
      % This is the default behavior: take the sum
      v     = sum(v);
  end
  if nargout > 1
%       g   = sign(x).*min( 1, abs(x)./tau );
      % make more compatible with complex numbers
      g     = x./max( tau, abs(x) );
  end
end % new method

end % new method


% TFOCS v1.3 by Stephen Becker, Emmanuel Candes, and Michael Grant.
% Copyright 2013 California Institute of Technology and CVX Research.
% See the file LICENSE for full license information.
