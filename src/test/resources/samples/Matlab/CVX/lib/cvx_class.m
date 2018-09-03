function v = cvx_class( x, needsign, needreal, needzero )
if nargin < 2, needsign = false; end
if nargin < 3, needreal = false; end
if nargin < 4, needzero = needsign; end

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
% ---
% 14 - constant
% 15 - affine
% 16 - real constant

if isempty( x ),
    v = 'empty';
    return
end
persistent remap_s remap_r remap_z strs
if isempty( strs ),
    remap_s = [16,2,16,4,5,6,7,8,9,10,11,12,13,14,15,16];
    remap_r = [1,2,3,14,5,15,7,15,9,10,11,12,13,14,15,14];
    remap_z = [1,14,3,4,5,6,7,8,9,10,11,12,13,14,15,16];
    strs = { 'negative constant', 'zero', 'positive constant', 'complex constant', ...
             'concave', 'real affine', 'convex', 'complex affine', ...
             'log-concave', 'log-affine', 'log-convex', 'log-convex', ...
             'invalid', 'constant', 'affine', 'real constant' };
end
x = cvx_classify( x );
if ~needsign,
    x = remap_s( x );
end
if ~needreal,
    x = remap_r( x );
end
if ~needzero,
    x = remap_z( x );
end
v = sparse( x, 1, 1, 16, 1 ) ~= 0;
if nnz( v ) ~= v( 2 ),
    v( 2 ) = false;
end
v = strs( v );
if length( v ) == 1,
    v = v{1};
else
    v = sprintf( '%s/', v{:} );
    v = [ 'mixed ', v(1:end-1) ];
end

% Copyright 2005-2016 CVX Research, Inc.
% See the file LICENSE.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.
