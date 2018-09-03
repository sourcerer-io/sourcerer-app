function op = smooth_linear( c, d )

%SMOOTH_LINEAR   Linear function generation.
%   FUNC = SMOOTH_LINEAR( C, D ) returns a function handle that provides a
%   TFOCS-compatible implementation of a linear function: if
%       [F,G] = FUNC(X),
%   then F = TFOCS_DOT(C,X)+D and G = C. D is optional; if omitted, then 
%   D == 0 is assumed. But if it is supplied, D must be a real scalar.
%   If C == 0, then this function is equivalent to SMOOTH_CONSTANT( D ).
%   This function can be used in both smooth and non-smooth contexts.

error(nargchk(1,2,nargin));
if nargin < 2,
    d = 0;
elseif ~isa( d, 'double' ) || ~isreal( d ) || numel( d ) ~= 1,
    error( 'Second argument must be a real scalar.' );
end
if nnz(c),
    op = @(varargin)smooth_linear_impl( c, d, varargin{:} );
else
    op = smooth_constant( d );
end

function [ v, g ] = smooth_linear_impl( c, d, x, t )
switch nargin,
    case 3,
        g = c;
    case 4,
        x = x - t * c;
        g = x;
    otherwise,
        error( 'Not enough arguments.' );
end
v = tfocs_dot( c, x ) + d;

% TFOCS v1.3 by Stephen Becker, Emmanuel Candes, and Michael Grant.
% Copyright 2013 California Institute of Technology and CVX Research.
% See the file LICENSE for full license information.
