function disp( x, prefix, inpname, nohead )

% DISP	Manual display. DISP(x,prefix) adds the string prefix to each
%       line of the display output.

if nargin < 3, inpname = ''; end
if nargin < 2, prefix = ''; end
n = numel( x.value_ );
if nargin < 4,
    fprintf( '%stfocs tuple object:\n', prefix );
    prefix = [ prefix, '   ' ];
end
for k = 1 : n,
    ss = x.value_{k};
    inpname2 = sprintf( '%s{%d}', inpname, k );
    if isnumeric( ss ),
        cls = class( ss );
        sz = size( ss );
        temp = sprintf( '%dx', sz );
        if all( sz == 1 ),
            fprintf( '%s%s: [%g]\n', prefix, inpname2, ss );
        elseif isreal(ss),
            fprintf( '%s%s: [%s %s]\n', prefix, inpname2, temp(1:end-1), cls );
        else
            fprintf( '%s%s: [%s %s complex]\n', prefix, inpname2, temp(1:end-1), cls );
        end
    elseif isa( ss, 'tfocs_tuple' ),
        fprintf( '%s%s: tfocs tuple object\n', prefix, inpname2 );
        disp( ss, [ prefix, inpname2 ], '', 1 );
    else
        fprintf( '%s%s: %s\n', prefix, inpname2, class(ss) );
    end
end

% TFOCS v1.3 by Stephen Becker, Emmanuel Candes, and Michael Grant.
% Copyright 2013 California Institute of Technology and CVX Research.
% See the file LICENSE for full license information.
