function disp( x, prefix )
if nargin < 2,
    prefix = '';
end
disp( [ prefix, 'cvx tuple object: ' ] );
prefix = [ prefix, '   ' ];
do_disp( x.value_, {}, prefix, prefix, '' );
if ~isempty( x.dual_ ),
    dn = cvx_subs2str( x.dual_ );
    disp( [ prefix, 'dual variable: ', dn(2:end) ] );
end

function do_disp( x, f, fprefix, prefix, suffix )
switch class( x ),
    case 'struct',
        do_disp( struct2cell(x), fieldnames(x), fprefix, prefix, suffix );
    case 'cell',
        fprefix = [ fprefix, '{ ' ];
        prefix  = [ prefix, '  ' ];
        nsuffix = '';
        kend = numel( x );
        for k = 1 : kend,
            if k == kend, nsuffix = [ ' }', suffix ]; end
            if ~isempty( f ),
                fprefix = sprintf( '%s%s: ', fprefix, f{k} );
            end
            do_disp( x{k}, {}, fprefix, prefix, nsuffix );
            fprefix = prefix;
        end
    case 'cvx',
        dual = cvx_getdual( x );
        if ~isempty( dual ),
            suffix = sprintf( ' (dual: %s)%s', dual, suffix );
        end
        disp( [ fprefix, cvx_class( x, true, true ), ' ', type( x ), suffix ] );
    case 'double',
        fprintf( 1, '%s%g%s\n', fprefix, x, suffix );
end

% Copyright 2005-2016 CVX Research, Inc.
% See the file LICENSE.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.
