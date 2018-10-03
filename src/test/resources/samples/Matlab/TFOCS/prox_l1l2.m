function op = prox_l1l2( q )

%PROX_L1L2    L1-L2 block norm: sum of L2 norms of rows.
%    OP = PROX_L1L2( q ) implements the nonsmooth function
%        OP(X) = q * sum_{i=1:m} norm(X(i,:),2)
%    where X is a m x n matrix.  If n = 1, this is equivalent
%    to PROX_L1
%    Q is optional; if omitted, Q=1 is assumed. But if Q is supplied,
%    then it must be positive and real.
%    If Q is a vector, it must be m x 1, and in this case,
%    the weighted norm OP(X) = sum_{i} Q(i)*norm(X(i,:),2)
%    is calculated.
%
% Dual: proj_linfl2.m
% See also proj_linfl2.m, proj_l1l2.m

if nargin == 0,
	q = 1;
% elseif ~isnumeric( q ) || ~isreal( q ) || numel( q ) ~= 1 || q <= 0,
elseif ~isnumeric( q ) || ~isreal( q ) || any(q <= 0),
	error( 'Argument must be positive.' );
end
% In r2007a and later, we can use bsxfun instead of the spdiags trick
if exist('OCTAVE_VERSION','builtin')
    vr = '2010';
else
    vr=version('-release');
end
if str2num(vr(1:4)) >= 2007
    op = tfocs_prox( @(x)f(q,x), @(x,t)prox_f_bsxfun(q,x,t) );
else
    % the default, using spdiags
    op = tfocs_prox( @(x)f(q,x), @(x,t)prox_f(q,x,t) );
end

function v = f(q,x)
    if numel(q) ~= 1 && size(q,1) ~= size(x,1)
        error('Weight must be a scalar or a column vector');
    end
    v = sum( q.* sqrt(sum(x.^2,2)) );
end

function x = prox_f(q,x,t) 
  if nargin < 3,
      error( 'Not enough arguments.' );
  end
  % v = sqrt( tfocs_normsq( x ) );
  v = sqrt( sum(x.^2,2) );
  s = 1 - 1 ./ max( v ./ ( t .* q ), 1 );
  m = length(s);
  x = spdiags(s,0,m,m)*x;
end
function x = prox_f_bsxfun(q,x,t)
  if nargin < 3,
      error( 'Not enough arguments.' );
  end
  v = sqrt( sum(x.^2,2) );
  s = 1 - 1 ./ max( v ./ ( t .* q ), 1 );
  x = bsxfun( @times, x, s ); % Apr 24 2013. Should be faster
end

end

% TFOCS v1.3 by Stephen Becker, Emmanuel Candes, and Michael Grant.
% Copyright 2013 California Institute of Technology and CVX Research.
% See the file LICENSE for full license information.
