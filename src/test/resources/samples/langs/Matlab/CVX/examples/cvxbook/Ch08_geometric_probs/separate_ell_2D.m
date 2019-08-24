% Separating ellipsoids in 2D
% Joelle Skaf - 11/06/05
% (a figure is generated)
%
% Finds a separating hyperplane between 2 ellipsoids {x| ||Ax+b||^2<=1} and
% {y | ||Cy + d||^2 <=1} by solving the following problem and using its
% dual variables:
%               minimize    ||w||
%                   s.t.    ||Ax + b||^2 <= 1       : lambda
%                           ||Cy + d||^2 <= 1       : mu
%                           x - y == w              : z
% the vector z will define a separating hyperplane because z'*(x-y)>0

% input data
n = 2;
A = eye(n);
b = zeros(n,1);
C = [2 1; -.5 1];
d = [-3; -3];

% solving for the minimum distance between the 2 ellipsoids and finding
% the dual variables
cvx_begin
    variables x(n) y(n) w(n)
    dual variables lam muu z
    minimize ( norm(w,2) )
    subject to
    lam:    square_pos( norm (A*x + b) ) <= 1;
    muu:    square_pos( norm (C*y + d) ) <= 1;
    z:      x - y == w;
cvx_end


t = (x + y)/2;
p=z;
p(1) = z(2); p(2) = -z(1);
c = linspace(-2,2,100);
q = repmat(t,1,length(c)) +p*c;

% figure
nopts = 1000;
angles = linspace(0,2*pi,nopts);
[u,v] = meshgrid([-2:0.01:4]);
z1 = (A(1,1)*u + A(1,2)*v + b(1)).^2 + (A(2,1)*u + A(2,2)*v + b(2)).^2;
z2 = (C(1,1)*u + C(1,2)*v + d(1)).^2 + (C(2,1)*u + C(2,2)*v + d(2)).^2;
contour(u,v,z1,[1 1]);
hold on;
contour(u,v,z2,[1 1]);
axis square
plot(x(1),x(2),'r+');
plot(y(1),y(2),'b+');
line([x(1) y(1)],[x(2) y(2)]);
plot(q(1,:),q(2,:),'k');
