function x = cvx_collapse( x, keeptemp, tocell )
if nargin < 2, keeptemp = false; end
if nargin < 3, tocell = false; end

while true,
    sx = size( x );
    nx = prod( sx );
    switch class( x ),
        case 'cell',
            if nx == 1,
                x = x{1};
                continue;
            end
            x = reshape( x, 1, nx );
        case 'struct',
            fx = fieldnames( x );
            if ~keeptemp,
                ndxs = horzcat( fx{:} );
                ndxs = ndxs( cumsum( cellfun( 'length', fx ) ) ) ~= '_';
                fx   = fx( ndxs );
            end
            nfx = length( fx );
            if nfx == 1 && nx == 1,
                x = subsref( x, struct( 'type', '.', 'subs', fx{1} ) );
                continue;
            end
            if tocell,
                if nfx == 1,
                    sx = [ 1, sx ]; %#ok
                else
                    sx = [ 1, nfx, sx ]; %#ok
                end
                x = struct2cell( x );
                if ~keeptemp,
                    x = x( ndxs, : );
                end
                x = reshape( x, sx );
            end
    end
    break;
end

% Copyright 2005-2016 CVX Research, Inc.
% See the file LICENSE.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.
