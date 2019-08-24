function op = linop_vec( sz )
%LINOP_VEC Matrix to vector reshape operator
%OP = LINOP_VEC( SZ )
%    Constructs a TFOCS-compatible linear operator that reduces a matrix
%    variable to a vector version using column-major order.
%    This is equivalent to X(:)
%    The transpose operator will reshape a vector into a matrix.
%
%    The input SZ should of the form [M,N] where [M,N] describe the
%    size of the matrix variable.  The ouput vector will be of 
%    length M*N.  If SZ is a single entry, then M = N is assumed.
%    For advanced usage with multidimensional arrays,
%    use the more general linop_reshape function instead.
%
%   To do the reverse operation (from vector to matrix),
%   use this function together with linop_adjoint.
%
%   See also linop_reshape

if numel(sz) > 2, error('must supply a 2-entry vector'); end
if numel(sz) == 1, sz = [sz(1),sz(1)]; end

% Switch conventions of the size variable:
sz = { [sz(1),sz(2)], [sz(1)*sz(2),1] };
 
op = @(x,mode)linop_handles_vec( sz, x, mode );

function y = linop_handles_vec(sz, x, mode )
switch mode,
    case 0, y = sz;
    case 1, y = x(:);
    case 2, 
        MN = sz{1}; M = MN(1); N = MN(2);
        y = reshape( x, M, N );
        
end

% TFOCS v1.3 by Stephen Becker, Emmanuel Candes, and Michael Grant.
% Copyright 2013 California Institute of Technology and CVX Research.
% See the file LICENSE for full license information.
