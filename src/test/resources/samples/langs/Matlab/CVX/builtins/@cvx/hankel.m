function H = hankel(c,r)

%Disciplined convex/geometric programming information for HANKEL:
%   HANKEL imposes no convexity restrictions on its arguments. Instead
%   of using the HANKEL function, however, consider creating a matrix
%   variable using the 'hankel' or 'upper_hankel' keyword; e.g.
%       variable X(5,5) hankel;
%       variable Y(4,4) upper_hankel;

%
% Check arguments
%

narginchk(1,2);
if nargin < 2,
    r = zeros(size(c));
else
    temp = cvx_subsref( r, 1 ) - cvx_subsref( c, numel(c) );
    if ~cvx_isnonzero( temp ),
        warning('MATLAB:hankel:AntiDiagonalConflict',['Last element of ' ...
               'input column does not match first element of input row. ' ...
               '\n         Column wins anti-diagonal conflict.'])
    end
end

%
% Compute indices and construct data vector
%

r  = vec( r );
c  = vec( c );
nc = length( c );
nr = length( r );
x  = [ c ; cvx_subsref( r, 2 : nr, 1 ) ];

%
% Construct matrix
%

cidx = ( 1 : nc )';
ridx = 0 : nr - 1;
H    = cidx(:,ones(nr,1)) + ridx(ones(nc,1),:);
H    = reshape( cvx_subsref( x, H( : ) ), size( H ) );

% Copyright 2005-2016 CVX Research, Inc.
% See the file LICENSE.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.
