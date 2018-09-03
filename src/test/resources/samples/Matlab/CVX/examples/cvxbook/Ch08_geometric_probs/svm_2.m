% Figure 8.11: Approximate linear discrimination via support vector classifier
% Section 8.6.1, Boyd & Vandenberghe "Convex Optimization"
% Original by Lieven Vandenberghe
% Adapted for CVX by Joelle Skaf - 10/16/05
% (a figure is generated)
%
% The goal is to find a function f(x) = a'*x - b that classifies the non-
% separable points {x_1,...,x_N} and {y_1,...,y_M} by doing a trade-off
% between the number of misclassifications and the width of the separating
% slab. a and b can be obtained by solving the following problem:
%           minimize    ||a||_2 + gamma*(1'*u + 1'*v)
%               s.t.    a'*x_i - b >= 1 - u_i        for i = 1,...,N
%                       a'*y_i - b <= -(1 - v_i)     for i = 1,...,M
%                       u >= 0 and v >= 0
% where gamma gives the relative weight of the number of misclassified
% points compared to the width of the slab.

% data generation
n = 2;
randn('state',2);
N = 50; M = 50;
Y = [1.5+0.9*randn(1,0.6*N), 1.5+0.7*randn(1,0.4*N);
     2*(randn(1,0.6*N)+1), 2*(randn(1,0.4*N)-1)];
X = [-1.5+0.9*randn(1,0.6*M),  -1.5+0.7*randn(1,0.4*M);
      2*(randn(1,0.6*M)-1), 2*(randn(1,0.4*M)+1)];
T = [-1 1; 1 1];
Y = T*Y;  X = T*X;
g = 0.1;            % gamma

% Solution via CVX
cvx_begin
    variables a(n) b(1) u(N) v(M)
    minimize (norm(a) + g*(ones(1,N)*u + ones(1,M)*v))
    X'*a - b >= 1 - u;
    Y'*a - b <= -(1 - v);
    u >= 0;
    v >= 0;
cvx_end

% Displaying results
linewidth = 0.5;  % for the squares and circles
t_min = min([X(1,:),Y(1,:)]);
t_max = max([X(1,:),Y(1,:)]);
tt = linspace(t_min-1,t_max+1,100);
p = -a(1)*tt/a(2) + b/a(2);
p1 = -a(1)*tt/a(2) + (b+1)/a(2);
p2 = -a(1)*tt/a(2) + (b-1)/a(2);

graph = plot(X(1,:),X(2,:), 'o', Y(1,:), Y(2,:), 'o');
set(graph(1),'LineWidth',linewidth);
set(graph(2),'LineWidth',linewidth);
set(graph(2),'MarkerFaceColor',[0 0.5 0]);
hold on;
plot(tt,p, '-r', tt,p1, '--r', tt,p2, '--r');
axis equal
title('Approximate linear discrimination via support vector classifier');
% print -deps svc-discr2.eps
