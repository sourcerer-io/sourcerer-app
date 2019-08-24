% Example 6.8: Spline fitting
% Section 6.5.3, Figure 6.20
% Boyd & Vandenberghe "Convex Optimization"
% Original by Lieven Vandenberghe
% Adapted for CVX by Joelle Skaf - 10/03/05
% (a figure is generated)
%
% Given data u_1,...,u_m and v_1,...,v_m in R, the goal is to fit to the
% data piecewise polynomials with maximum degree 3 (with continuous first
% and second derivatives).
% The [0,1] interval is divided into 3 equal intervals: [-1, -1/3],
% [-1/3,1/3], [1/3,1] with the following polynomials defined on each
% interval respectively:
% p1(t) = x11 + x12*t + x13*t^2 + x14*t^3
% p2(t) = x21 + x22*t + x23*t^2 + x24*t^3
% p3(t) = x31 + x32*t + x33*t^2 + x34*t^3
% L2-norm and Linfty-norm cases are considered

% Input Data
n=4;  % variables per segment
m=40;
randn('state',0);
% generate 50 points ui, vi
u = linspace(-1,1,m);
v = 1./(5+40*u.^2) + 0.1*u.^3 + 0.01*randn(1,m);

a = -1/3;  b = 1/3;  % boundary points
u1 = u(find(u<a)); m1 = length(u1);
u2 = u(find((u >= a) & (u<b)));  m2 = length(u2);
u3 = u(find((u >= b)));  m3 = length(u3);

A1 = vander(u1');   A1 = fliplr(A1(:,m1-n+[1:n]));
A2 = vander(u2');   A2 = fliplr(A2(:,m2-n+[1:n]));
A3 = vander(u3');   A3 = fliplr(A3(:,m3-n+[1:n]));

%L-2 fit
fprintf(1,'Computing splines in the case of L2-norm...');

cvx_begin
    variables x1(n) x2(n) x3(n)
    minimize ( norm( [A1*x1;A2*x2;A3*x3] - v') )
    %continuity conditions at point a
    [1 a a^2   a^3]*x1 == [1 a a^2   a^3]*x2;
    [0 1 2*a 3*a^2]*x1 == [0 1 2*a 3*a^2]*x2;
    [0 0   2 6*a  ]*x1 == [0 0   2 6*a  ]*x2;
    %continuity conditions at point b
    [1 b b^2   b^3]*x2 == [1 b b^2   b^3]*x3;
    [0 1 2*b 3*b^2]*x2 == [0 1 2*b 3*b^2]*x3;
    [0 0   2 6*b  ]*x2 == [0 0   2 6*b  ]*x3;
cvx_end

fprintf(1,'Done! \n');

% L-infty fit
fprintf(1,'Computing splines in the case of Linfty-norm...');

cvx_begin
    variables xl1(n) xl2(n) xl3(n)
    minimize ( norm( [A1*xl1;A2*xl2;A3*xl3] - v', inf) )
    %continuity conditions at point a
    [1 a a^2   a^3]*xl1 == [1 a a^2   a^3]*xl2;
    [0 1 2*a 3*a^2]*xl1 == [0 1 2*a 3*a^2]*xl2;
    [0 0   2 6*a  ]*xl1 == [0 0   2 6*a  ]*xl2;
    %continuity conditions at point b
    [1 b b^2   b^3]*xl2 == [1 b b^2   b^3]*xl3;
    [0 1 2*b 3*b^2]*xl2 == [0 1 2*b 3*b^2]*xl3;
    [0 0   2 6*b  ]*xl2 == [0 0   2 6*b  ]*xl3;
cvx_end

fprintf(1,'Done! \n');

% evaluate the interpolating polynomials using Horner's method
u1s = linspace(-1.0,a,1000)';
p1 = x1(1) + x1(2)*u1s + x1(3)*u1s.^2 + x1(4).*u1s.^3;
p1l1 = xl1(1) + xl1(2)*u1s + xl1(3)*u1s.^2 + xl1(4).*u1s.^3;

u2s = linspace(a,b,1000)';
p2 = x2(1) + x2(2)*u2s + x2(3)*u2s.^2 + x2(4).*u2s.^3;
p2l1 = xl2(1) + xl2(2)*u2s + xl2(3)*u2s.^2 + xl2(4).*u2s.^3;

u3s = linspace(b,1.0,1000)';
p3 = x3(1) + x3(2)*u3s + x3(3)*u3s.^2 + x3(4).*u3s.^3;
p3l1 = xl3(1) + xl3(2)*u3s + xl3(3)*u3s.^2 + xl3(4).*u3s.^3;

us = [u1s;u2s;u3s];
p = [p1;p2;p3];
pl = [p1l1;p2l1;p3l1];
% plot function and cubic splines
d = plot(us,p,'b-',u,v,'go', us,pl,'r--',...
         [-1 -1], [-0.1 0.25], 'k--', [1 1], [-0.1 0.25], 'k--', ...
         [a a], [-0.1 0.25], 'k--', [b b], [-0.1 0.25], 'k--');

title('Approximation using 2 cubic splines');
xlabel('u');
ylabel('f(u)');
legend('L_2 norm','Data points','L_{\infty} norm', 'Location','Best');
% print -deps splineapprox.eps
