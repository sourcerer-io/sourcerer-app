% Minimum volume ellipsoid covering a finite set
% Section 8.4.1, Boyd & Vandenberghe "Convex Optimization"
% Almir Mutapcic - 10/05
% (a figure is generated)
%
% Given a finite set of points x_i in R^2, we find the minimum volume
% ellipsoid (described by matrix A and vector b) that covers all of
% the points by solving the optimization problem:
%
%           maximize     log det A
%           subject to   || A x_i + b || <= 1   for all i
%
% CVX cannot yet handle the logdet function, but this problem can be
% represented in an equivalent way as follows:
%
%           maximize     det(A)^(1/n)
%           subject to   || A x_i + b || <= 1   for all i
%
% The expression det(A)^(1/n) is SDP-representable, and is implemented
% by the MATLAB function det_rootn().

% Generate data
x = [ 0.55  0.0;
      0.25  0.35
     -0.2   0.2
     -0.25 -0.1
     -0.0  -0.3
      0.4  -0.2 ]';
[n,m] = size(x);

% Create and solve the model
cvx_begin
    variable A(n,n) symmetric
    variable b(n)
    maximize( det_rootn( A ) )
    subject to
        norms( A * x + b * ones( 1, m ), 2 ) <= 1;
cvx_end

% Plot the results
clf
noangles = 200;
angles   = linspace( 0, 2 * pi, noangles );
ellipse  = A \ [ cos(angles) - b(1) ; sin(angles) - b(2) ];
plot( x(1,:), x(2,:), 'ro', ellipse(1,:), ellipse(2,:), 'b-' );
axis off

