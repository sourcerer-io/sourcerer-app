function y = sum( x, dim )

%   Disciplined convex/geometric programming information for SUM:
%      SUM(X) and SUM(X,DIM) is a vectorized version of addition. So 
%      when SUM is used in a DCP or DGP, elements in each subvector must
%      satisfy the corresponding combination rules for addition (see 
%      PLUS). For example, suppose that X looks like this:
%         X = [ convex concave affine  ;
%               affine concave concave ]
%      Then SUM(X,1) would be permittted, but SUM(X,2) would not, 
%      because the top row contains the sum of convex and concave terms,
%      in violation of the DCP ruleset. For DGPs, addition rules dictate
%      that the elements of X must be log-convex or log-affine.

%
% Basic argument check
%

s = size( x );
switch nargin,
    case 0,
        error( 'Not enough input arguments.' );
    case 1,
        dim = [ find( s > 1 ), 1 ];
        dim = dim( 1 );
    case 2,
        if ~isnumeric( dim ) || dim <= 0 || dim ~= floor( dim ),
            error( 'Second argument must be a dimension.' );
        end
end

if dim > length( s ) || s( dim ) == 1,

    y = x;

elseif s( dim ) == 0,

    if ~any( s ), s = [1,1];
    else s( dim ) = 1; end
    y = cvx( s, sparse( 1, prod( s ) ) );

else

    p  = prod( s( 1 : dim - 1 ) );
    cc = 0 : prod( s ) - 1;
    cl = rem( cc, p );
    cr = floor( cc / ( p * s( dim ) ) );
    cc = cl + cr * p + 1;
    s( dim ) = 1;
    b = x.basis_;
    [ r, c, v ] = find( b );
    b = sparse( r, cc( c ), v, size( b, 1 ), prod( s ) );
    y = cvx( s, b );
    v = cvx_vexity( y );
    if any( isnan( v( : ) ) ),
        error( 'Disciplined convex programming error:\n   Illegal addition encountered (e.g., {convex} + {concave}).', 1 ); %#ok
    end

end

% Copyright 2005-2016 CVX Research, Inc.
% See the file LICENSE.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.
