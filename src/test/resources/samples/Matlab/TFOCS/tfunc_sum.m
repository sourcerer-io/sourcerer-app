function op = tfunc_sum( varargin )

%TFUNC_SUM Sum of functions.
%    OP = TFUNC_SUM( F1, F2, ..., FN ) implements
%        OP( x ) = F1( x ) + F2( x ) + ... + FN( x ).
%    Each entry must be a real scalar or a function handle. You are
%    responsible for ensuring that the sum is convex or concave, as
%    appropriate; TFOCS cannot verify this.

for k = 1 : nargin,
    arg = varargin{k};
    if ~isa( arg, 'function_handle' ) && ( ~isnumeric( arg ) || numel( arg ) ~= 1 || ~isreal( arg ) ),
        error( 'Arguments must be function handles or real scalars.' );
    elseif isnumeric( arg ),
        varargin{k} = smooth_constant( arg );
    end
end
switch nargin,
    case 0,
        op = smooth_constant( 0 );
    case 1,
        op = varargin{1};
    otherwise,
        op = @(x)tfunc_sum_impl( varargin, x );
end

function [ v, g ] = tfunc_sum_impl( args, x, t )
if nargin > 2,
    error( 'This function does not support proximity minimization.' );
elseif nargout == 1,
    v = args{1}( x );
    for k = 2 : numel(args),
        v = v + args{k}( x );
    end
else
    [ v, g ] = args{1}( x );
    for k = 2 : numel(args),
        [ nv, ng ] = args{k}( x );
        v = v + nv;
        g = g + ng;
    end
end

% TFOCS v1.3 by Stephen Becker, Emmanuel Candes, and Michael Grant.
% Copyright 2013 California Institute of Technology and CVX Research.
% See the file LICENSE for full license information.
