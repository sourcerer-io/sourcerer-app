function y = testall( func, x )
y = do_test( func, x.value_ );

function y = do_test( func, x )
switch class( x ),
    case 'struct',
        y = do_test( func, struct2cell( x ) );
    case 'cell',
        y = all( cellfun( func, x ) );
    otherwise,
        y = feval( func, x );
end

% Copyright 2005-2016 CVX Research, Inc. 
% See the file LICENSE.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.
