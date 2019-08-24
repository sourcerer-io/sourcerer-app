% Figure 8.9: Robust linear discrimination problem
% Section 8.6.1, Boyd & Vandenberghe "Convex Optimization"
% Original by Lieven Vandenberghe
% Adapted for CVX by Joelle Skaf - 10/16/05
% (a figure is generated)
%
% The goal is to find a function f(x) = a'*x - b that classifies the points
% {x_1,...,x_N} and {y_1,...,y_M} with maximal 'gap'. a and b can be
% obtained by solving the following problem:
%           maximize    t
%               s.t.    a'*x_i - b >=  t     for i = 1,...,N
%                       a'*y_i - b <= -t     for i = 1,...,M
%                       ||a||_2 <= 1

% data generation
n = 2;
randn('state',3);
N = 10; M = 6;
Y = [1.5+1*randn(1,M); 2*randn(1,M)];
X = [-1.5+1*randn(1,N); 2*randn(1,N)];
T = [-1 1; 1 1];
Y = T*Y;  X = T*X;

% Solution via CVX
cvx_begin
    variables a(n) b(1) t(1)
    maximize (t)
    X'*a - b >= t;
    Y'*a - b <= -t;
    norm(a) <= 1;
cvx_end

% Displaying results
linewidth = 0.5;  % for the squares and circles
t_min = min([X(1,:),Y(1,:)]);
t_max = max([X(1,:),Y(1,:)]);
tt = linspace(t_min-1,t_max+1,100);
p = -a(1)*tt/a(2) + b/a(2);
p1 = -a(1)*tt/a(2) + (b+t)/a(2);
p2 = -a(1)*tt/a(2) + (b-t)/a(2);

graph = plot(X(1,:),X(2,:), 'o', Y(1,:), Y(2,:), 'o');
set(graph(1),'LineWidth',linewidth);
set(graph(2),'LineWidth',linewidth);
set(graph(2),'MarkerFaceColor',[0 0.5 0]);
hold on;
plot(tt,p, '-r', tt,p1, '--r', tt,p2, '--r');
axis equal
title('Robust linear discrimination problem');
% print -deps linsep.eps
