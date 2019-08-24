function y = cvx_default_dimension( sx )

%CVX_DEFAULT_DIMENSION   Default dimension for SUM, MAX, etc. 
%   DIM = CVX_DEFAULT_DIMENSION( SX ), where SX is a size vector, returns the
%   first index DIM such that SX(DIM)>1, if one exists; otherwise, DIM=1. This
%   matches the behavior by functions like SUM, MAX, ANY, ALL, etc. in
%   selecting the dimension over which to operate if DIM is not supplied.
%
%   For example, suppose size(X) = [1,3,4]; then SUM(X) would sum over dimension
%   2; and DIM=CVX_DEFAULT_DIMENSION([1,3,4]) returns DIM=2.
%
%   This is an internal CVX function, and as such no checking is performed to
%   insure that the arguments are valid.

y = find( sx ~= 1 );
if isempty( y ), 
    y = 1; 
else
    y = y( 1 ); 
end

% Copyright 2005-2016 CVX Research, Inc. 
% See the file LICENSE.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.
