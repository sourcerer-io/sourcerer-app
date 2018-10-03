function op = prox_linf( q )

%PROX_LINF    L-infinity norm.
%    OP = PROX_LINF( q ) implements the nonsmooth function
%        OP(X) = q * norm( X(:), Inf ).
%    Q is optional; if omitted, Q=1 is assumed. But if Q is supplied,
%    then it must be a positive real scalar.
% Dual: proj_l1.m
% See also proj_l1

if nargin == 0,
	q = 1;
elseif ~isnumeric( q ) || ~isreal( q ) || numel( q ) ~= 1 || q <= 0,
	error( 'Argument must be positive.' );
end
op = @(varargin)prox_linf_q( q, varargin{:} );

function [ v, x ] = prox_linf_q( q, x, t )
if nargin < 2,
    error( 'Not enough arguments.' );
end    
tau = norm( x(:), Inf );
if nargin == 3,
    s   = sort( abs(nonzeros(x)), 'descend' ); % makes one big vector
    
    cs  = cumsum(s);
    ndx = find( cs - (1:numel(s))' .* [s(2:end);0] >= t * q, 1 );
    if ~isempty( ndx ),
        tau = ( cs(ndx) - t * q ) / ndx;
        x   = x .* ( tau ./ max( abs(x), tau ) );
    else
        x(:) = 0;  % adding Oct 21
        tau = 0;
    end
elseif nargout == 2,
    error( 'This function is not differentiable.' );
end
v = q * tau;

% TFOCS v1.3 by Stephen Becker, Emmanuel Candes, and Michael Grant.
% Copyright 2013 California Institute of Technology and CVX Research.
% See the file LICENSE for full license information.
