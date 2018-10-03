% Minimal phase spectral factorization
%
% A PSD matrix is found which minimizes a weighted trace while obtaining
% fixed sums along the diagonals. Notice the use of a FOR loop to access
% the diagonals of X. A later version of CVX will eliminate the need for
% this by allowing the use of the SPDIAGS function in side models.
% Nevertheless, this example provides an illustration of the use of
% standard Matlab control statements to build models.
%
% Adapted from an example provided in the SeDuMi documentation.

% Generate data
b = [2; 0.2; -0.3];
n = length( b );

% Create and solve model
cvx_begin sdp
    variable X( n, n ) symmetric
    dual variable y{n}
    dual variable Z
    minimize( ( n - 1 : -1 : 0 ) * diag( X ) );
    for k = 1 : n,
        sum( diag( X, k - 1 ) ) == b( k ) : y{k};
    end
    X >= 0 : Z;
cvx_end
y = [ y{:} ]';

% Display resuls
disp( 'The optimal point, X:' );
disp( X )
disp( 'The diagonal sums:' );
disp( sum( spdiags( X, 0:n-1 ), 1 ) );
disp( 'min( eig( X ) ) (should be nonnegative):' );
disp( min( eig( X ) ) )
disp( 'The optimal weighted trace:' );
disp( ( n - 1 : -1 : 0 ) * diag( X ) );
