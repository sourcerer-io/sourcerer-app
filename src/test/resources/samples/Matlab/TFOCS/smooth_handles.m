function op = smooth_handles( func, grad )

%SMOOTH_HANDLES Smooth function from separate f/g handles.
%    OP = SMOOTH_HANDLES( func, grad ) constructs a TFOCS-compatible
%    smooth function from separate handles for computing the function
%    value and gradient.
%
%   See also private/tfocs_smooth

op = @(varargin)smooth_handles_impl( func, grad, varargin{:} );

function [ f, g ] = smooth_handles_impl( fop, gop, x, t )
switch nargin,
	case 3,
		f = fop( x );
		if nargout > 1,
			g = gop( x );
		end
	case 4,
		error( 'This function does not support proximity minimizaztion.' );
	case { 0, 1, 2 },
		error( 'Not enough input arguments.' );
end		

% TFOCS v1.3 by Stephen Becker, Emmanuel Candes, and Michael Grant.
% Copyright 2013 California Institute of Technology and CVX Research.
% See the file LICENSE for full license information.
