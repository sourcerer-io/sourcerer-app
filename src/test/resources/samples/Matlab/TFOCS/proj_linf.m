function op = proj_linf( q )

%PROJ_LINF   Projection onto the scaled infinity norm ball.
%    OP = PROJ_LINF( Q ) returns an operator implementing the 
%    indicator function for the infinity norm ball of size q,
%    { X | norm( X, Inf ) <= q }. Q is optional; if omitted,
%    Q=1 is assumed. But if Q is supplied, it must be a positive
%    real scalar.
% Dual: prox_l1.m
% See also: prox_l1, prox_linf, proj_l1

if nargin == 0,
	q = 1;
elseif ~isnumeric( q ) || ~isreal( q ) || numel( q ) ~= 1 || q <= 0,
	error( 'Argument must be positive.' );
end
op = @(varargin)proj_linf_q( q, varargin{:} );

function [ v, x ] = proj_linf_q( q, x, t )
v = 0;
switch nargin,
	case 2,
		if nargout == 2,
			error( 'This function is not differentiable.' );
		elseif norm( x(:), Inf ) > q,
			v = Inf;
		end
	case 3,			
        x = x ./ max( 1, abs( x / q ) );
	otherwise,
		error( 'Not enough arguments.' );
end

% TFOCS v1.3 by Stephen Becker, Emmanuel Candes, and Michael Grant.
% Copyright 2013 California Institute of Technology and CVX Research.
% See the file LICENSE for full license information.
