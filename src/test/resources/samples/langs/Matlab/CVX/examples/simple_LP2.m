% Builds and solves a simple inequality-constrained linear program

echo on

n = 10;
A = randn(2*n,n);
b = randn(2*n,1);
c = randn(n,1);
d = randn;
cvx_begin
   variable x(n)
   dual variables y z
   minimize( c' * x + d )
   subject to
      y : A * x <= b;
cvx_end

echo off

