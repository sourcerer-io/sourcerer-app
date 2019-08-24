function op = proj_Rplus( scale )

%PROJ_RPLUS    Projection onto the nonnegative orthant.
%    OP = PROJ_RPLUS returns an implementation of the indicator 
%    function for the nonnegative orthant.
%    OP2 = PROJ_RPLUS( scale ) returns the indicator function
%    of the scaled nonnegative orthant: that is,
%        OP2( x ) = OP( scale * x ).
%    Because the nonnegative orthant is a cone, scaling has no
%    effect if scale > 0. If scale < 0, the result is an 
%    indicator function for the nonpositive orthant, which is
%    also the conjugate of the original. If scale == 0, then
%    the result is the zero function.
% Dual: proj_Rplus(-1)
%
% See also proj_psd.m, the matrix-analog of this function

if nargin == 0,
    op = @proj_Rplus_impl;
elseif ~isa( scale, 'double' ) || numel( scale ) ~= 1 || ~isreal( scale ),
    error( 'The argument must be a real scalar.' );
elseif scale > 0,
    op = @proj_Rplus_impl;
elseif scale < 0,
    op = @proj_Rminus_impl;
else
    op = proj_Rn;
end

function [ v, x ] = proj_Rplus_impl( x, t )
v = 0;
switch nargin,
	case 1,
		if nargout == 2,
			error( 'This function is not differentiable.' );
        elseif any( x(:) < 0 ),
            v = Inf;
        end
	case 2,
		x = max( x, 0 );
	otherwise,
		error( 'Not enough arguments.' );
end

function [ v, x ] = proj_Rminus_impl( x, t )
v = 0;
switch nargin,
	case 1,
		if nargout == 2,
			error( 'This function is not differentiable.' );
        elseif any( x(:) > 0 ),
            v = Inf;
        end
	case 2,
		x = min( x, 0 );
	otherwise,
		error( 'Not enough arguments.' );
end

% TFOCS v1.3 by Stephen Becker, Emmanuel Candes, and Michael Grant.
% Copyright 2013 California Institute of Technology and CVX Research.
% See the file LICENSE for full license information.
