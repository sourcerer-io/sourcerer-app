% Equality constrained norm minimization.
%
% This script constructs a random equality-constrained norm minimization
% problem and solves it using CVX. You can also change p to +2 or +Inf
% to produce different results. Alternatively, you an replace
%     norm( A * x - b, p )
% with
%     norm_largest( A * x - b, 'largest', p )
% for 1 <= p <= 2 * n.

% Generate data
p = 1;
n = 10; m = 2*n; q=0.5*n;
A = randn(m,n);
b = randn(m,1);
C = randn(q,n);
d = randn(q,1);

% Create and solve problem
cvx_begin
   variable x(n)
   dual variable y
   minimize( norm( A * x - b, p ) )
   subject to
        y : C * x == d;
cvx_end

% Display results
disp( sprintf( 'norm(A*x-b,%g):', p ) );
disp( [ '   ans   =   ', sprintf( '%7.4f', norm(A*x-b,p) ) ] );
disp( 'Optimal vector:' );
disp( [ '   x     = [ ', sprintf( '%7.4f ', x ), ']' ] );
disp( 'Residual vector:' );
disp( [ '   A*x-b = [ ', sprintf( '%7.4f ', A*x-b ), ']' ] );
disp( 'Equality constraints:' );
disp( [ '   C*x   = [ ', sprintf( '%7.4f ', C*x ), ']' ] );
disp( [ '   d     = [ ', sprintf( '%7.4f ', d   ), ']' ] );
disp( 'Lagrange multiplier for C*x==d:' );
disp( [ '   y     = [ ', sprintf( '%7.4f ', y ), ']' ] );
