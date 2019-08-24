function st = type( x, usegeo )

df  = x.dof_;
if nargin > 1 && usegeo,
    geo = any( df < 0 );
else
    geo = false;
end
df  = abs( df );
s   = x.size_;
len = prod( s );

if len == 1,
    isstruct = 0;
    nzs = len;
    st = 'scalar';
else
    isstruct = ~isempty( df ) & ( sum( df ) < ( 2 - isreal( x.basis_ ) ) * len );
    if ~isstruct,
        nzs = nnz( any( x.basis_, 1 ) );
    end
    nd = length( s );
    st = sprintf( '%dx', s );
    st = st( 1 : end - 1 );
    if nd > 2,
        st = [ st, ' array' ];
    elseif any( s == 1 ),
        st = [ st, ' vector' ];
    else
        st = [ st, ' matrix' ];
    end
end

if isstruct,
    st = sprintf( '%s, %d d.o.f.', st, df );
elseif nzs < len,
    if nzs > 1,
        st = sprintf( '%s, %d nonzeros', st, nzs );
    elseif nzs == 1,
        st = sprintf( '%s, 1 nonzero', st );
    end
end
if geo,
    st = [ st, ', geometric' ];
end

% Copyright 2005-2016 CVX Research, Inc.
% See the file LICENSE.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.
