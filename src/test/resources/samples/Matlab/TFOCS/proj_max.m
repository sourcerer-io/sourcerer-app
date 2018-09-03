function op = proj_max( q )

%PROJ_max   Projection onto the scaled max-function ball.
%    OP = PROJ_MAX( Q ) returns an operator implementing the 
%    indicator function for the max-function ball of size q,
%    { X | max( X(:) ) <= q }. Q is optional; if omitted,
%    Q=1 is assumed. But if Q is supplied, it must be a 
%    real scalar (negative is OK).
% Dual: prox_l1pos.m
% See also: prox_l1pos, prox_linf, proj_l1, proj_linf

if nargin == 0,
	q = 1;
elseif ~isnumeric( q ) || ~isreal( q ) || numel( q ) ~= 1 
	error( 'Argument "q" must be a real scalar.' );
end
op = @(varargin)proj_linf_q( q, varargin{:} );

function [ v, x ] = proj_linf_q( q, x, t )
v = 0;
switch nargin,
	case 2,
		if nargout == 2,
			error( 'This function is not differentiable.' );
		elseif max( x(:) ) > q,
			v = Inf;
		end
	case 3,			
        x = min( x, q );
	otherwise,
		error( 'Not enough arguments.' );
end

% TFOCS v1.3 by Stephen Becker, Emmanuel Candes, and Michael Grant.
% Copyright 2013 California Institute of Technology and CVX Research.
% See the file LICENSE for full license information.
