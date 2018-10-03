function op = proj_l1( q, d )
%PROJ_L1   Projection onto the scaled 1-norm ball.
%    OP = PROJ_L1( Q ) returns an operator implementing the 
%    indicator function for the 1-norm ball of radius q,
%    { X | norm( X, 1 ) <= q }. Q is optional; if omitted,
%    Q=1 is assumed. But if Q is supplied, it must be a positive
%    real scalar.
%
%    OP = PROJ_L1( Q, D ) uses a scaled 1-norm ball of radius q,
%    { X | norm( D.*X, 1 ) <= 1 }. D should be the same size as X
%    and non-negative (some zero entries are OK).
%
% Dual: prox_linf.m
% See also: prox_linf, prox_l1, proj_linf

if nargin == 0,
	q = 1;
elseif ~isnumeric( q ) || ~isreal( q ) || numel( q ) ~= 1 || q <= 0,
	error( 'Argument must be positive.' );
end
if nargin < 2 || isempty(d) || numel(d)==1
    if nargin>=2 && ~isempty(d)
        % d is a scalar, so norm( d*x ) <= q is same as norm(x)<=q/d
        if d==0
            error('If d==0 in proj_l1, the set is just {0}, so use proj_0');
        elseif d < 0
            error('Require d >= 0');
        end
        q = q/d;
    end
    op = @(varargin)proj_l1_q(q, varargin{:} );
else
    if any(d<0)
        error('All entries of d must be non-negative');
    end
    op = @(varargin)proj_l1_q_d(q, d, varargin{:} );
end

function [ v, x ] = proj_l1_q( q, x, t )
v = 0;
switch nargin,
case 2,
	if nargout == 2,
		error( 'This function is not differentiable.'  );
	elseif norm( x(:), 1 ) > q,
		v = Inf;
	end
case 3,
    s      = sort(abs(nonzeros(x)),'descend');
    cs     = cumsum(s);
    % ndx    = find( cs - (1:numel(s))' .* [ s(2:end) ; 0 ] >= q, 1 );
    ndx    = find( cs - (1:numel(s))' .* [ s(2:end) ; 0 ] >= q+2*eps(q), 1 ); % For stability
    if ~isempty( ndx )
        thresh = ( cs(ndx) - q ) / ndx;
        x      = x .* ( 1 - thresh ./ max( abs(x), thresh ) ); % May divide very small numbers
    end
otherwise,
    error( 'Not enough arguments.' );
end

% Allows scaling. Added Feb 21 2014
function [ v, x ] = proj_l1_q_d( q, d,  x, t )
v = 0;
switch nargin,
case 3,
	if nargout == 2,
		error( 'This function is not differentiable.'  );
	elseif norm( d(:).*x(:), 1 ) > q,
		v = Inf;
	end
case 4,
    [lambdas,srt]      = sort(abs(nonzeros(x./d)),'descend');
    s   = abs(x(:).*d(:));  s = s(srt);
    dd  = d(:).^2;          dd= dd(srt);
    cs  = cumsum(s);
    cd  = cumsum(dd);
    ndx    = find( cs - lambdas.*cd >= q+2*eps(q), 1, 'first');
    if ~isempty( ndx )
        ndx     = ndx - 1;
        lambda  = ( cs(ndx) - q )/cd(ndx);
        x       = sign(x).*max( 0, abs(x) - lambda*d );
    end
otherwise,
    error( 'Not enough arguments.' );
end

% TFOCS v1.3 by Stephen Becker, Emmanuel Candes, and Michael Grant.
% Copyright 2013 California Institute of Technology and CVX Research.
% See the file LICENSE for full license information.
