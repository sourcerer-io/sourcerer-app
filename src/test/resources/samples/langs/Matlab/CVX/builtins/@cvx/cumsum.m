function y = cumsum( x, dim )

%Disciplined convex/geometric programming information for SUM:
%   CUMSUM(X) and CUMSUM(X,DIM) are vectorized forms of addition. So 
%   when CUMSUM is used in a DCP or DGP, elements in each subvector 
%   must satisfy the corresponding combination rules for addition (see
%   PLUS). For example, suppose that X looks like this:
%      X = [ convex concave affine  ;
%            affine concave concave ]
%   Then CUMSUM(X,1) would be permittted, but CUMSUM(X,2) would not, 
%   because the top row contains the sum of convex and concave terms, in
%   violation of the DCP ruleset. For DGPs, addition rules dictate that
%   the elements of X must be log-convex or log-affine.

s = x.size_;
switch nargin,
    case 0,
        error( 'Not enough input arguments.' );
    case 1,
        dim = cvx_default_dimension( s );
    case 2,
        if ~cvx_check_dimension( dim, false ),
            error( 'Second argument must be a dimension.' );
        end
end

if dim > length( s ) || s( dim ) <= 1,

    y = x;

else

    b = x.basis_;
    sb = size( b );
    need_perm = any( s( dim + 1 : end ) > 1 );
    if need_perm,
        ndxs = reshape( 1 : prod( s ), s );
        ndxs = permute( ndxs, [ 1 : dim - 1, dim + 1 : length( s ), dim ] );
        b = b( :, ndxs );
    end
    b = reshape( b, prod( sb ) / s( dim ), s( dim ) );
    b = cumsum( b, 2 );
    b = reshape( b, sb );
    if need_perm,
        b( :, ndxs ) = b;
    end
    y = cvx( s, b );
    v = cvx_vexity( y );
    if any( isnan( v( : ) ) ),
        error( 'Disciplined convex programming error:\n   Illegal addition encountered (e.g., {convex} + {concave}).', 1 ); %#ok
    end

end

% Copyright 2005-2016 CVX Research, Inc.
% See the file LICENSE.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.
