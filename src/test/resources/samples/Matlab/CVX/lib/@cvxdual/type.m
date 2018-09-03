function st = type( x )

x = cvxaff( x );
if isa( x, 'double' ),
    st = 'unassigned';
    return
end
if iscell( x ),
    strs = cell(1,numel(x));
    for k = 1 : numel(x),
        strs{k} = type(x{k});
    end
    strs = sprintf( '%s, ', strs{:} );
    st = strs(1:end-2);
    return
end
s   = size( x );
len = prod( s );
isr = isreal( x );
if len == 1,
    if isr,
        st = 'scalar';
    else
        st = 'complex scalar';
    end
else
    dof = size( cvx_basis( x ), 2 ) - 1;
    isstruct = dof < ( 2 - isr ) * len;
    st = sprintf( '%dx', s );
    st = st( 1 : end - 1 );
    if ~isr,
        st = [ st, ' complex' ];
    end
    if length( s ) > 2,
        st = [ st, ' array' ];
    elseif any( s == 1 ),
        st = [ st, ' vector' ];
    else
        st = [ st, ' matrix' ];
    end
    if isstruct,
        st = sprintf( '%s (%d d.o.f.)', st, dof );
    end
end

% Copyright 2005-2016 CVX Research, Inc.
% See the file LICENSE.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.
