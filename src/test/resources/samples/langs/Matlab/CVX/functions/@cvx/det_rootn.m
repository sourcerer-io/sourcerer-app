function cvx_optval = det_rootn( X )

%DET_ROOTN   Internal cvx version.

narginchk(1,1);
n = size( X, 1 );
if ndims( X ) > 2, %#ok

    error( 'N-D arrays are not supported.' );

elseif size( X, 2 ) ~= n,

    error( 'Matrix must be square.' );

elseif nnz( X ) <= n && nnz( diag( X ) ) == nnz( X ),

    cvx_optval = geo_mean( diag( X ) );

elseif cvx_isconstant( X ),

    cvx_optval = cvx( det_rootn( cvx_constant( X ) ) );

elseif isreal( X ),

	Z = [];
    cvx_begin
        variable Z(n,n) lower_triangular
        D = diag( Z );
        maximize( geo_mean( D ) );
        subject to
            [ diag( D ), Z' ; Z, X ] == semidefinite(2*n); %#ok
    cvx_end

else

	Z = [];
    cvx_begin
        variable Z(n,n) lower_triangular complex
        D = diag( Z );
        maximize( geo_mean( real( D ) ) );
        subject to
            [ diag( D ), Z' ; Z, X ] == hermitian_semidefinite(2*n); %#ok
    cvx_end

end

% Copyright 2005-2016 CVX Research, Inc.
% See the file LICENSE.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.
