% Figure 8.8: Simplest linear discrimination
% Boyd & Vandenberghe "Convex Optimization"
% Joelle Skaf - 10/16/05
% (a figure is generated)
%
% The goal is to find a function f(x) = a'*x - b that classifies the points
% {x_1,...,x_N} and {y_1,...,y_M}. a and b can be obtained by solving a
% feasibility problem:
%           minimize    0
%               s.t.    a'*x_i - b >=  1     for i = 1,...,N
%                       a'*y_i - b <= -1     for i = 1,...,M

% data generation
n = 2;
randn('state',3);
N = 10; M = 6;
Y = [1.5+1*randn(1,M); 2*randn(1,M)];
X = [-1.5+1*randn(1,N); 2*randn(1,N)];
T = [-1 1; 1 1];
Y = T*Y;  X = T*X;

% Solution via CVX
fprintf('Finding a separating hyperplane...');

cvx_begin
    variables a(n) b(1)
    X'*a - b >= 1;
    Y'*a - b <= -1;
cvx_end

fprintf(1,'Done! \n');

% Displaying results
linewidth = 0.5;  % for the squares and circles
t_min = min([X(1,:),Y(1,:)]);
t_max = max([X(1,:),Y(1,:)]);
t = linspace(t_min-1,t_max+1,100);
p = -a(1)*t/a(2) + b/a(2);

graph = plot(X(1,:),X(2,:), 'o', Y(1,:), Y(2,:), 'o');
set(graph(1),'LineWidth',linewidth);
set(graph(2),'LineWidth',linewidth);
set(graph(2),'MarkerFaceColor',[0 0.5 0]);
hold on;
plot(t,p, '-r');
axis equal
title('Simple classification using an affine function');
% print -deps lin-discr.eps
