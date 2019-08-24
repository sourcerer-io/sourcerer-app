function v = cvx_classify( x )

% Classifications:
% 1  - negative constant
% 2  - zero
% 3  - positive constant
% 4  - complex constant
% 5  - concave
% 6  - real affine
% 7  - convex
% 8  - complex affine
% 9  - log concave
% 10 - log affine
% 11 - log convex monomial
% 12 - log convex posynomial
% 13 - invalid

v = full( sign( real( x ) ) ) + 2;
if ~isreal( x ),
	v( imag( x ) ~= 0 ) = 4;
end
v( ~isfinite( x ) ) = 13;
v = reshape( v, 1, numel( x ) );

% Copyright 2005-2016 CVX Research, Inc.
% See the file LICENSE.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.
