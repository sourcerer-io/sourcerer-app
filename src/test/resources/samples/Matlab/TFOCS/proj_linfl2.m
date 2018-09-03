function op = proj_linfl2( q )

%PROJ_LINFL2   Projection of each row onto the scaled l2 norm ball.
%    OP = PROJ_LINFL2( Q ) returns an operator implementing the 
%    indicator function for the set of l2 norm ball of size q,
%    { X | for all rows i, norm( X(i,:),2) <= q }. Q is optional; if omitted,
%    Q=1 is assumed. But if Q is supplied, it must be a positive
%    real scalar.
% Dual: prox_l1l2.m
% See also: prox_l1, prox_linf, proj_l1

if nargin == 0,
	q = 1;
elseif ~isnumeric( q ) || ~isreal( q ) || numel( q ) ~= 1 || q <= 0,
	error( 'Argument must be positive.' );
end

% In r2007a and later, we can use bsxfun instead of the spdiags trick
if exist('OCTAVE_VERSION','builtin')
    vr = '2000';
else
    vr=version('-release');
end
if str2num(vr(1:4)) >= 2007
    op = @(varargin)proj_linfl2_q_bsxfun( q, varargin{:} );
else
    % the default, using spdiags
    op = @(varargin)proj_linfl2_q( q, varargin{:} );
end

function [ v, x ] = proj_linfl2_q( q, x, t )
v = 0;
switch nargin,
	case 2,
		if nargout == 2,
			error( 'This function is not differentiable.' );
		elseif norm( x(:), Inf ) > q,
			v = Inf;
		end
	case 3,			
        % Compute the norms of the rows
        m = size(x,1);
        nrms = sqrt( sum( abs(x).^2 , 2 ) );
        % Scale the rows using left diagonal multiplication
        x = spdiags( min(1,q./nrms), 0, m, m )*x;
	otherwise,
		error( 'Not enough arguments.' );
end

function [ v, x ] = proj_linfl2_q_bsxfun( q, x, t )
v = 0;
switch nargin,
	case 2,
		if nargout == 2,
			error( 'This function is not differentiable.' );
		elseif norm( x(:), Inf ) > q,
			v = Inf;
		end
	case 3,			
        nrms = sqrt( sum( abs(x).^2 , 2 ) );
        bsxfun( @times, x, min(1,q./nrms) );
	otherwise,
		error( 'Not enough arguments.' );
end

% TFOCS v1.3 by Stephen Becker, Emmanuel Candes, and Michael Grant.
% Copyright 2013 California Institute of Technology and CVX Research.
% See the file LICENSE for full license information.
