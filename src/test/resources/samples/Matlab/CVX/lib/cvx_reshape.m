function x = cvx_reshape( x, s, rmap, cperm, cperm2 )
sx = size( x );
if nargin < 5,
    cperm2 = [];
    if nargin < 4,
        cperm = [];
        if nargin < 3,
            rmap = [];
            if nargin < 2,
                s = sx;
            end
        end
    end
end
usp = cvx_use_sparse( s, nnz( x ), isreal( x ) );
isp = issparse( x );
if ~usp && isp, 
    x = full( x ); 
end
if ~isequal( s, sx ) || ~isempty( rmap ) || ~isempty( cperm ) || ~isempty( cperm2 ),
    if usp && ( numel( x ) > 2147483647 || ~isempty( rmap ) || ~isempty( cperm ) ),
        [ ii, jj, x ] = find( x );
        if ~isempty( rmap ),
            sx( 1 ) = length( rmap );
            rmap = find( rmap );
            ii = rmap( ii );
        end
        if ~isempty( cperm ),
            temp = 1 : sx( 2 );
            temp( cperm ) = temp;
            jj = temp( :, jj )';
        end
        ij = ii + ( jj - 1 ) * sx( 1 ) - 1;
        ii = rem( ij, s( 1 ) ) + 1;
        jj = floor( ij / s( 1 ) ) + 1;
        if ~isempty( cperm2 ),
            temp = 1 : s( 2 );
            temp( cperm2 ) = temp;
            jj = temp( :, jj )';
        end
        x = sparse( ii, jj, x, s( 1 ), s( 2 ) );
        clear ii jj ij
        isp = true;
    else
        if ~isempty( cperm ),
            x = x( :, cperm );
        end
        if ~isempty( rmap ),
            x = x( max( 1, cumsum( rmap ) ), : );
            x( ~rmap, : ) = 0;
        end
        x = reshape( x, s );
        if ~isempty( cperm2 ),
            x = x( :, cperm2 );
        end
    end
end
if usp && ~isp,
    x = sparse( x ); 
end

% Copyright 2005-2016 CVX Research, Inc.
% See the file LICENSE.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.

