function op = smooth_constant( d )

%SMOOTH_CONSTANT   Constant function generation.
%   FUNC = SMOOTH_CONSTANT( D ) returns a function handle that provides
%   a TFOCS-compatible implementation of the constant function F(X) = D.
%   D must be a real scalar. The function can be used in both a smooth
%   and a nonsmooth context.

error(nargchk(1,1,nargin));
if ~isa( d, 'double' ) || ~isreal( d ) || numel( d ) ~= 1,
    error( 'Argument must be a real scalar.' );
end
op = @(varargin)smooth_constant_impl( d, varargin{:} );

function [ v, g ] = smooth_constant_impl( v, x, t )
switch nargin,
    case 2,
        if nargin > 1,
            g = 0 * x;
        end
    case 3,
        g = x;
    otherwise,
        error( 'Not enough arguments.' );
end

% TFOCS v1.3 by Stephen Becker, Emmanuel Candes, and Michael Grant.
% Copyright 2013 California Institute of Technology and CVX Research.
% See the file LICENSE for full license information.
