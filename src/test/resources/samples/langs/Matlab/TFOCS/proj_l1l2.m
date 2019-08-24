function op = proj_l1l2( q, rowNorms )

%PROJ_L1L2    L1-L2 block norm: sum of L2 norms of rows.
%    OP = PROJ_L1L2( q ) implements the constraint set
%        {X | sum_{i=1:m} norm(X(i,:),2) <= 1 }
%    where X is a m x n matrix.  If n = 1, this is equivalent
%    to PROJ_L1. If m=1, this is equivalent to PROJ_L2
%
%    Q is optional; if omitted, Q=1 is assumed. But if Q is supplied,
%    then it must be positive and real and a scalar.
%
%   OP = PROJ_L1L2( q, rowNorms )
%     will either do the sum of the l2-norms of rows if rowNorms=true
%       (the default), or the sum of the l2-norms of columns if
%       rowNorms = false.
%
%   Known issues: doesn't yet work with complex-valued data.
%       Should be easy to fix, so email developers if this is
%       needed for your problem.
%
% Dual: prox_linfl2.m [not yet available]
% See also prox_l1l2.m, proj_l1.m, proj_l2.m

if nargin == 0 || isempty(q),
	q = 1;
% elseif ~isnumeric( q ) || ~isreal( q ) || numel( q ) ~= 1 || q <= 0,
elseif ~isnumeric( q ) || ~isreal( q ) || any(q <= 0) ||numel(q)>1,
	error( 'Argument must be positive and a scalar.' );
end

if nargin<2 || isempty(rowNorms)
    rowNorms = true;
end

if rowNorms
    op = tfocs_prox( @(x)f_rows(q,x), @(x,t)prox_f_rows(q,x,t) );
else
    op = tfocs_prox( @(x)f_cols(q,x), @(x,t)prox_f_cols(q,x,t) );
end

function v = f_rows(tau,X)
    nrm = sum( sqrt( sum( X.^2, 2 ) ) );
    if nrm <= tau + 5*eps(tau)
        v = 0;
    else
        v = Inf;
    end
end
function v = f_cols(tau,X)
    nrm = sum( sqrt( sum( X.^2, 1 ) ) );
    if nrm <= tau + 5*eps(tau)
        v = 0;
    else
        v = Inf;
    end
end



function X = prox_f_rows(tau,X,t) 
  if nargin < 3,
      error( 'Not enough arguments.' );
  end
  
  nrms    = sqrt( sum( X.^2, 2 ) );
  % When we include a row of x, corresponding to row y of Y,
  % its contribution is norm(y)-lambda
  % So we have sum_{i=1}^m max(0, norm(y_0)-lambda)
  % So, basically project nrms onto the l1 ball...
  s      = sort( nrms, 'descend' );
  cs     = cumsum(s);
  
  ndx    = find( cs - (1:numel(s))' .* [ s(2:end) ; 0 ] >= tau+2*eps(tau), 1 ); % For stability
  
  if ~isempty( ndx )
      thresh = ( cs(ndx) - tau ) / ndx;
      %     x      = x .* ( 1 - thresh ./ max( abs(x), thresh ) ); % May divide very small numbers
      
      % Apply to relevant rows
      d   = max( 0, 1-thresh./nrms );
      m   = size(X,1);
      X   = spdiags( d, 0, m, m )*X;
  end
end

function X = prox_f_cols(tau,X,t) 
  if nargin < 3,
      error( 'Not enough arguments.' );
  end
  
  nrms    = sqrt( sum( X.^2, 1 ) ).';
  % When we include a row of x, corresponding to row y of Y,
  % its contribution is norm(y)-lambda
  % So we have sum_{i=1}^m max(0, norm(y_0)-lambda)
  % So, basically project nrms onto the l1 ball...
  s      = sort( nrms, 'descend' );
  cs     = cumsum(s);
  
  ndx    = find( cs - (1:numel(s))' .* [ s(2:end) ; 0 ] >= tau+2*eps(tau), 1 ); % For stability
  
  if ~isempty( ndx )
      thresh = ( cs(ndx) - tau ) / ndx;
      %     x      = x .* ( 1 - thresh ./ max( abs(x), thresh ) ); % May divide very small numbers
      
      % Apply to relevant rows
      d   = max( 0, 1-thresh./nrms );
      n   = size(X,2);
      X   = X*spdiags( d, 0, n,n );
  end
end



end

% TFOCS v1.3 by Stephen Becker, Emmanuel Candes, and Michael Grant.
% Copyright 2015 California Institute of Technology and CVX Research.
% See the file LICENSE for full license information.
