function op = prox_l1linf( q )

%PROX_L1LINF    L1-LInf block norm: sum of L-inf norms of rows.
%    OP = PROX_L1LINF( q ) implements the nonsmooth function
%        OP(X) = q * sum_{i=1:m} norm(X(i,:),Inf)
%    where X is a m x n matrix.  If n = 1, this is equivalent
%    to PROX_L1
%    Q is optional; if omitted, Q=1 is assumed. But if Q is supplied,
%    then it must be positive and real.
%    If Q is a vector, it must be m x 1, and in this case,
%    the weighted norm OP(X) = sum_{i} Q(i)*norm(X(i,:),Inf)
%    is calculated.

if nargin == 0,
	q = 1;
elseif ~isnumeric( q ) || ~isreal( q ) || any(q <= 0),
	error( 'Argument must be positive.' );
end
op = tfocs_prox( @(x)f(x,q), @(x,t)prox_f(x,t,q), 'vector' );
end % end of main function

function v = f(x,q)
    if numel(q) ~= 1 && size(q,1) ~= size(x,1)
        error('Weight must be a scalar or a column vector');
    end
    v = sum( q.* max(abs(x),[],2) );
end

function x = prox_f(x,t,q)
  if nargin < 2,
      error( 'Not enough arguments.' );
  end
  
  [n,d] = size(x);
  dim   = 2;
  
  % Option 1: explicitly call prox_linf on the rows:
  % slow, but the chief benefit is that it is low memory
  % This would probably be faster if the matrix was transposed before and after
%   for k= 1:n
%       if isscalar(q), qk = q;
%       else, qk = q(k);
%       end 
%       x(k,:) = prox_linf_q( qk, x(k,:).', t ).';
%   end
%   return;
  

  
% Option 2: vectorize the call.  By far, more efficient than option 1

  %s     = sort( abs(x), dim, 'descend' );
  %cs    = cumsum(s,dim);
  % Since Matlab stores matrices in column-major order, this method is more cache friendly:
  s     = sort( abs(x)', q, 'descend' );
  cs    = cumsum(s,1)';
  s     = s';

  s     = [s(:,2:end), zeros(n,1)];
  

  ndx1 = zeros(n,1);
  ndx2 = zeros(n,1);
  
  if isscalar(q),
      tq = repmat( t*q, n, d );
  else
      tq = repmat( t*q, 1, d );
  end
  %Z = cs - s*diag(1:d);
  % The above may require a lot of memory, so use spdiag or this:
  Z = cs - bsxfun(@times,s,1:d);

  Z = ( Z >= tq );
  Z = Z.';
  % now Z is d x n (typically d is large, n is small) 
  
  % Not sure how to vectorize the find.
  % One option is to use the [i,j] = find(...) form,
  % but that's also extra work, since we can't just find the "first".
  if n > 5
      % avoid the for-loop
      ndx1  = (d+1)-sum(Z)'; % this is the first row with Z > 0
      ndx2  = ndx1;
      ndx2( ndx2 == d+1 ) = Inf;
      ndx1( ndx1 == d+1)  = d; % arbitrary, but do this so we don't have a special case later
  else
      % this might be slightly less memory, so keep the code
      for k = 1:n
          % This is why we transposed Z: due to column-major order,
          %     find( columnVector ) is faster than find( rowVector )
          ndxk = find( Z(:,k), 1 );
          if ~isempty(ndxk)
              ndx1(k) = ndxk;
              ndx2(k) = ndxk;
          else
              ndx1(k) = 1; % value doesn't matter
              ndx2(k) = Inf;
          end
      end
  end
  indx_cs = sub2ind( [n,d], (1:n)', ndx1 );
  tau = (cs(indx_cs) - tq(:,1))./ndx2;
  tau = repmat( tau, 1, d );
  tau_noZeros = tau;
  tau_noZeros( ~x ) = 1;
  x   = x .* (  tau ./ max( abs(x), tau_noZeros ) );
  % Another, but not really better, way is to not do the rempat stuff and do:
  % x     = sign(x).*bsxfun( @min, tau, abs(x) );
  
  
end


% TFOCS v1.3 by Stephen Becker, Emmanuel Candes, and Michael Grant.
% Copyright 2013 California Institute of Technology and CVX Research.
% See the file LICENSE for full license information.
