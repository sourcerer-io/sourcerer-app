function v = cvx_vexity( x )

global cvx___
s = x.size_;
if any( s == 0 ),
    v = cvx_zeros( s );
    return
end
p  = cvx___.vexity;
b  = x.basis_;
n  = length( p );
nb = size( b, 1 );
if nb < n,
    p = p( 1 : nb, 1 );
elseif n < nb,
    p( nb, 1 ) = 0;
end
if ~any( p ),
    v = cvx_zeros( x.size_ );
    if x.slow_,
        v( isnan( x.basis_( 1, : ) ) ) = NaN;
    end
    return
end
b = b( p ~= 0, : );
p = nonzeros(p).';
if cvx___.nan_used,
    b = sparse( b );
end
v = full( p * b );
tt = abs( v ) ~= abs( p ) * abs( b );
if x.slow_,
    v( tt | isnan( x.basis_( 1, : ) ) ) = NaN;
else
    v( tt ) = NaN;
end
if ~isreal( x ),
    v( any( imag( x.basis_ ), 1 ) & v ) = NaN;
end
v = sign( v );
v = reshape( v, x.size_ );

% Copyright 2005-2016 CVX Research, Inc.
% See the file LICENSE.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.
