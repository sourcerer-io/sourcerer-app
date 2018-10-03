function lines = cvx_error( errmsg, widths, useline, prefix, chop )

% CVX_ERROR   Formats text for inclusion in error messages.
%    This is an internal function used by CVX. It needed to be in the CVX
%    home directory so that it's available during a fresh installation.

if ~ischar( errmsg ),
    if strncmp( errmsg.identifier, 'CVX:', 4 ),
        format = 'basic';
    else
        format = 'extended';
    end
    try
        errmsg = getReport( errmsg, format, 'hyperlinks', 'off' );
        errmsg = regexprep( errmsg,'</?a[^>]*>', '' );
    catch
        if isfield(errmsg,'stack') && length(errmsg.stack) >= 1,
            errmsg = sprintf( '%s\n    Line %d: %s\n', errmsg.message, errmsg.stack(1).line, errmsg.stack(1).file );
        else
            errmsg = sprintf( '%s\n', errmsg.message );
        end
    end
end
lines = {};
rndx = [ 0, regexp( errmsg, '\n' ), length(errmsg) + 1 ];
for k = 1 : length(rndx) - 1,
    line = errmsg( rndx(k)+1 : rndx(k+1) - 1 );
    if ~isempty( line ),
        width    = widths( min( k, length(widths) ) );
        emax     = length( line );
        n_indent = 0;
        if emax > width,
            f_indent = sum( regexp( line, '[^ ]', 'once' ) - 1 );
            sndxs = find( line == ' ' );
        end
        while true,
            if emax + n_indent <= width || isempty( sndxs ),
                lines{end+1} = [ 32 * ones(1,n_indent), line ];
                break;
            end
            sndx = sndxs( sndxs <= width - n_indent + 1 );
            if isempty( sndx ), sndx = sndxs(1); end
            chunk = line(1:sndx(end)-1);
            lines{end+1} = [ 32*ones(1,n_indent), chunk ]; %#ok
            line(1:sndx(end)) = [];
            sndxs = sndxs(length(sndx)+1:end) - sndx(end);
            emax = emax - sndx(end);
            n_indent = f_indent + 4;
        end
    end
end
if nargin >= 3 && ( ischar(useline) || useline ),
    line = '-';
    line = line(1,ones(1,max(cellfun(@length,lines))));
    sline = line;
    if ischar( useline ),
        sline(1:length(useline)) = useline;
    end
    lines = [ sline, lines, line ];
end
if nargout == 0 || nargin >= 4,
    if nargin < 4, prefix = ''; end
    lines = sprintf( [ prefix, '%s\n' ], lines{:} );
end
if nargin >= 5 && chop,
    lines(end) = [];
end
if nargout == 0,
    fprintf( '%s', lines );
    clear lines
end

% Copyright 2005-2016 CVX Research, Inc.
% See the file LICENSE.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.
