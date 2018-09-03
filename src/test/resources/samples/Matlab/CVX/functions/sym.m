function x = sym( x )

% SYM   Symmetrize.
%    SYM(X), where X is a matrix, returns the symmetric or Hermitian part
%    of X; that is, SYM(X) = 0.5 * ( X + X' ). If X is an array, SYM(X) 
%    symmetrizes each of the submatrices X(:,:,k). X must satisfy 
%    size(X,1) = size(X,2).
%
%    SYM(X) is useful in CVX when constructing LMIs. Sometimes, numerical
%    errors will cause a construct to be slightly non-symmetric, causing 
%    CVX to flag it as an error. If you are sure the asymmetry is solely
%    due to this effect, SYM(X) will correct it for you.

sx = size(x);
if sx(1) ~= sx(2),
    error( 'Argument must be square in its first two dimensions.' );
elseif sx(1) > 1,
    x = 0.5 * ( x + conj( permute( x, [2,1,3:length(sx)] ) ) );
end

% Copyright 2005-2016 CVX Research, Inc.
% See the file LICENSE.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.
