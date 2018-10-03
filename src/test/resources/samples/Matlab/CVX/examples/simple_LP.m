% Builds and solves a simple linear program

echo on

n = 100;
A = randn(0.5*n,n);
b = randn(0.5*n,1);
c = randn(n,1);
d = randn;
cvx_begin
   variable x(n)
   dual variables y z
   minimize( c' * x + d )
   subject to
      y : A * x == b;
      z : x >= 0;
cvx_end

echo off

