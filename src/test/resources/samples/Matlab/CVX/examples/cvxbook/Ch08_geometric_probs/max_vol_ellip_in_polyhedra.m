% Maximum volume inscribed ellipsoid in a polyhedron 
% Section 8.4.1, Boyd & Vandenberghe "Convex Optimization"
% Original version by Lieven Vandenberghe
% Updated for CVX by Almir Mutapcic - Jan 2006
% (a figure is generated)
%
% We find the ellipsoid E of maximum volume that lies inside of
% a polyhedra C described by a set of linear inequalities.
%
% C = { x | a_i^T x <= b_i, i = 1,...,m } (polyhedra)
% E = { Bu + d | || u || <= 1 } (ellipsoid) 
%
% This problem can be formulated as a log det maximization
% which can then be computed using the det_rootn function, ie,
%     maximize     log det B
%     subject to   || B a_i || + a_i^T d <= b,  for i = 1,...,m

% problem data
n = 2;
px = [0 .5 2 3 1];
py = [0 1 1.5 .5 -.5];
m = size(px,2);
pxint = sum(px)/m; pyint = sum(py)/m;
px = [px px(1)];
py = [py py(1)];

% generate A,b
A = zeros(m,n); b = zeros(m,1);
for i=1:m
  A(i,:) = null([px(i+1)-px(i) py(i+1)-py(i)])';
  b(i) = A(i,:)*.5*[px(i+1)+px(i); py(i+1)+py(i)];
  if A(i,:)*[pxint; pyint]-b(i)>0
    A(i,:) = -A(i,:);
    b(i) = -b(i);
  end
end

% formulate and solve the problem
cvx_begin
    variable B(n,n) symmetric
    variable d(n)
    maximize( det_rootn( B ) )
    subject to
       for i = 1:m
           norm( B*A(i,:)', 2 ) + A(i,:)*d <= b(i);
       end
cvx_end

% make the plots
noangles = 200;
angles   = linspace( 0, 2 * pi, noangles );
ellipse_inner  = B * [ cos(angles) ; sin(angles) ] + d * ones( 1, noangles );
ellipse_outer  = 2*B * [ cos(angles) ; sin(angles) ] + d * ones( 1, noangles );

clf
plot(px,py)
hold on
plot( ellipse_inner(1,:), ellipse_inner(2,:), 'r--' );
plot( ellipse_outer(1,:), ellipse_outer(2,:), 'r--' );
axis square
axis off
hold off
