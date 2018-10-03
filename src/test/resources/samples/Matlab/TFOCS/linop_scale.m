function op = linop_scale( scale, sz )

%LINOP_SCALE  Scaling linear operator.
%    OP = LINOP_SCALE( scale ) returns a handle to a TFOCS linear operator 
%    whose forward and adjoint operators are OP(X) = scale * X.
%    "scale" must be a real scalar
%
%    OP = LINOP_SCALE( scale, size ) gives the scaling operator
%       an explicit size. "sz" can be:
%           - the empty matrix "[]" (default), which means the size is not
%               yet defined; the TFOCS software will attempt to automatically
%               determine the size later.
%           - a vector [N1,N2] which implies the domain is the set of N1 x N2 matrices
%               ( it is also possible to use [N1,N2,N3,....], which
%                 means the domain is a set of multi-dimensional arrays )
%           - a scalar N, which is equivalent to [N,1], i.e. the set of N x 1 vectors
%       Because this is simple scaling, the range will have the same size
%       as the domain.
%
%   July 2016, allowing OP(X) = scale .* X  as well
%
%   See also linop_compose

if ~isnumeric( scale ) %&& numel( scale ) ~= 1,
    error( 'Argument must be numeric.' );
elseif ~isreal( scale ),
    error( 'Argument must be real.' );
end
if nargin < 2, sz = []; end
if isempty(sz)
    szCell = { [], [] };
elseif isnumeric(sz)
    if numel(sz) <= 1, sz = [sz, 1 ]; end
    % ensure that "sz" is a row vector
    sz = sz(:).';
    szCell = { sz, sz };
else
    error('bad type for size input');
end

if all(scale(:) == 1 ),
    op = @linop_identity;
else
    op = @(x,mode)linop_scale_impl( szCell, scale, x, mode );
end

function y = linop_scale_impl( sz, scale, y, mode )
if mode == 0, 
    y = sz;
else
    y = scale .* y;
end

% function OK = isSquare( sz )
% OK = true;
% for j = 1:length( sz{1} )
%     if sz{1}(j) ~= sz{2}(j)
%         OK = false; break;
%     end
% end

% TFOCS v1.3 by Stephen Becker, Emmanuel Candes, and Michael Grant.
% Copyright 2013 California Institute of Technology and CVX Research.
% See the file LICENSE for full license information.
