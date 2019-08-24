function x = setdual( x, y )
x.dual_ = y;
x.value_ = do_setdual( x.value_, y );

function x = do_setdual( x, y )
switch class( x ),
    case 'struct',
        nx = numel( x );
        if nx > 1,
            error( 'Dual variables may not be attached to struct arrays.' );
        end
        f = fieldnames(x);
        y(end+1).type = '{}';
        for k = 1 : length(f),
            y(end).subs = {1,k};
            x.(f{k}) = do_setdual( x.(f{k}), y );
        end
    case 'cell',
        y(end+1).type = '{}';
        y(end+1).subs = cell(1,ndims(x));
        for k = 1 : numel(nx),
            [ y(end).subs{:} ] = { 1, k };
            x{k} = do_setdual( x{k}, y );
        end
    case 'cvx',
        x = setdual( x, y );
    case 'double',
        x = setdual( cvx( x ), y );
end


% Copyright 2005-2016 CVX Research, Inc.
% See the file LICENSE.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.
