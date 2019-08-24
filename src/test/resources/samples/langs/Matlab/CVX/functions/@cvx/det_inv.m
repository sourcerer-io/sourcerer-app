function cvx_optval = det_inv( X, p )

%DET_INV   Internal cvx version.

narginchk(1,2);
n = size( X, 1 );
if ndims( X ) > 2, %#ok
    error( 'N-D arrays are not supported.' );
elseif size( X, 2 ) ~= n,
    error( 'Matrix must be square.' );
elseif nargin < 2,
    p = 1;
elseif ~isnumeric( p ) || ~isreal( p ) || numel( p ) ~=  1 || p <= 0,
    error( 'Second argument must be a positive scalar.' );
end

w = [ ones(n,1) ; p ];
if cvx_isconstant( X ),
    
    cvx_optval = cvx( det_inv( cvx_constant( X ), p ) );

elseif nnz( X ) <= n && nnz( diag( X ) ) == nnz( X ),
    
    y = [];
    cvx_begin
        epigraph variable y
        geo_mean( [ diag(X) ; y ], w ) >= 1; %#ok
    cvx_end

elseif isreal( X ),

	y = []; Z = [];
    cvx_begin
        epigraph variable y
        variable Z(n,n) lower_triangular
        D = diag( Z );
        [ diag( D ), Z' ; Z, X ] == semidefinite(2*n); %#ok
        geo_mean( [ D ; y ], [], w ) >= 1; %#ok
    cvx_end

else

	y = []; Z = [];
    cvx_begin
        epigraph variable y
        variable Z(n,n) lower_triangular complex
        D = diag( Z );
        [ diag( D ), Z' ; Z, X ] == hermitian_semidefinite(2*n); %#ok
        geo_mean( [ real( D ) ; y ], [], w ) >= 1; %#ok
    cvx_end

end

% Copyright 2005-2016 CVX Research, Inc.
% See the file LICENSE.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.
