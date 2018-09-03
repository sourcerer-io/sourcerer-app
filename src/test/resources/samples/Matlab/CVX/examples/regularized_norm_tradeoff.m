% Builds a norm minimization tradeoff curve
%
% This script solves a family of problems of the form
%     minimize || A*x-b ||_1 + gamma * || x ||_Inf
% for varying values of gamma. For gamma = 0, this is simply an
% unconstrained norm minimization; for gamma = Inf, x = 0 and
% || A x - b || = || b || are optimal. Varying gamma allows us
% to genreate a tradeoff curve between these extremes.

n = 10;
A = randn(2*n,n);
b = randn(2*n,1);
gamma = logspace( -1, 3 );
nrms = zeros( size( gamma ) );
xnrms = zeros( size( gamma ) );
fprintf( 1, 'Gamma: ' );
for k = 1 : length( gamma ),
   if k > 1 && rem( k, 10 ) == 1, fprintf( 1, '\n       ' ); end
   fprintf( 1, '%g ', gamma( k ) );
   cvx_begin quiet
      variable x(n)
      minimize( norm( A * x - b, 1 ) + gamma( k ) * norm( x, Inf ) )
   cvx_end
   nrms( k ) = norm( A * x - b, 1 );
   xnrms( k ) = norm( x, Inf );
end
fprintf( 1, 'done.\n' );
figure
semilogx( gamma, nrms );
xlabel( '\gamma' );
ylabel( '|| A * x - b ||_1' );
figure
plot( xnrms, nrms );
xlabel( '|| x ||_{\infty}' );
ylabel( '|| A * x - b ||_1' );
