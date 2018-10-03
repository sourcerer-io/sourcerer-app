function op = prox_shift( funcF, c )

%PROX_SHIFT Shift a proximity/projection function
%    SHIFTED_OP = PROX_SHIFT( OP, c )
%       returns an implementation of the proximity operator
%       defined by f(x) + c'*x
%       where f is the proximity operator associated with OP.
%
%   See also prox_scale

error(nargchk(2,2,nargin));
if ~isa( funcF, 'function_handle' ),
    error( 'The first argument must be a function handle.' );
elseif ~isnumeric( c ) 
    error( 'The second argument must be a numeric vector.' );
end
op = @(varargin)shift_func( funcF, c, varargin{:} );


function [ v, x ] = shift_func( prox_f, c, x, t )

    if nargin < 3,
        error( 'Not enough arguments.' );
    end
    if nargin == 4,
        if numel(t) ~= 1
            error('The stepsize must be a scalar'); 
        end
        [v,x]  = prox_f(x-t*c,t);
        v      = v + tfocs_dot(x,c);
    elseif nargout == 2,
        error( 'This function is not differentiable.' );
    end

% TFOCS v1.3 by Stephen Becker, Emmanuel Candes, and Michael Grant.
% Copyright 2015 California Institute of Technology and CVX Research.
% See the file LICENSE for full license information.
