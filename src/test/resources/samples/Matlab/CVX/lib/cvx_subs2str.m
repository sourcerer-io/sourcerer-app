function y = cvx_subs2str( x, mask, fieldalt )
if nargin < 2,
    mask = [ 1, 1, 1 ];
end
if nargin < 3,
    fieldalt = 0;
end
if ~isstruct( x ),
    error( 'First arugment must be a structure.' );
end
y = '';
needfield = fieldalt ~= 0;
for k = 1 : length( x ),
    try
        tp = x(k).type;
    catch %#ok
        error( 'Invalid subscript structure: field "type" is missing.' );
    end
    if ~ischar( tp ) || size( tp, 1 ) ~= 1,
        error( 'Invalid subscript entry #%d: field "type" must be a string', k );
    end
    try
        sb = x(k).subs;
    catch %#ok
        error( 'Invalid subscript structure: field "subs" is missing.' );
    end
    switch tp,
        case '.',
            if ~ischar( sb ) || size( sb, 1 ) ~= 1,
                error( 'Invalid subscript entry #%d: field name must be a string.', k );
            elseif ~isvarname( sb ),
                error( 'Invalid subscript entry #%d: invalid field name: %s', k, sb );
            end
            y = [ y, '.', sb ]; %#ok
            needfield = 0;
        case { '()', '{}' },
            if ~mask( 2 )&& tp(1) == '(',
                error( 'Invalid subscript entry #%d: array subscripts not allowed here.', k );
            elseif ~mask( 3 ) && tp(1) == '{',
                error( 'Invalid subscript entry #%d: cell subscripts not allowed here.', k );
            elseif needfield,
                error( 'Invalid subscript entry #%d: structure field expected here.', k );
            elseif ~iscell( sb ),
                error( 'Invalid subscript entry #%d: field "subs" must be a cell array.', k );
            elseif fieldalt,
                needfield = 1;
            end
            for j = 1 : length( sb ),
                if isnumeric( sb{j} ),
                    sb{j} = sprintf('%g',sb{j});
                elseif ~ischar( sb{j} ) || size( sb{j}, 1 ) ~= 1,
                    error( 'Invalid subscript entry #%d: invalid cell/array subscript', j );
                end
            end
            sb = sprintf( '%s,', sb{:} );
            y = [ y, tp(1), sb(1:end-1), tp(2) ]; %#ok
        otherwise,
            error( 'Invalid subscript entry #%d: invalid subscript tp: %s', k, tp );
    end
end

% Copyright 2005-2016 CVX Research, Inc.
% See the file LICENSE.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.
