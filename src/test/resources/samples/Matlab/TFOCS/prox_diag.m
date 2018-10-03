function op = prox_diag( funcF, funcG, n )

%PROX_DIAG Shift a proximity/projection function
%    PROX_DIAG = PROX_DIAG( funcF, funcG, n )
%       returns an implementation of the proximity operator
%       defined by F( x(1:n) ) + G( x(n+1:end) )
%
%   For now, both F and G must accept vector inputs (not matrices)
%   (and this only works for 2 functions; to apply to 3 or more functions,
%    repeatedly apply this function recursively).
%

% Introduced June 2016

error(nargchk(3,3,nargin));
if ~isa( funcF, 'function_handle' ),
    error( 'The first argument must be a function handle.' );
elseif ~isa( funcG, 'function_handle' ), 
    error( 'The second argument must be a function handle.' );
end
op = @(varargin)prox_diag_impl( funcF, funcG, n, varargin{:} );


function [ v, x ] = prox_diag_impl( prox_f, prox_g, n, x, t )

    if nargin < 4,
        error( 'Not enough arguments.' );
    end
    if nargin == 5,
        if numel(t) ~= 1
            error('The stepsize must be a scalar'); 
        end
        [v1,x(1:n)]      = prox_f(x(1:n),t);
        [v2,x(n+1:end)]  = prox_g(x(n+1:end),t);
        v      = v1 + v2;
    elseif nargout == 2,
        error( 'This function is not differentiable.' );
    end

% TFOCS v1.3 by Stephen Becker, Emmanuel Candes, and Michael Grant.
% Copyright 2015 California Institute of Technology and CVX Research.
% See the file LICENSE for full license information.
