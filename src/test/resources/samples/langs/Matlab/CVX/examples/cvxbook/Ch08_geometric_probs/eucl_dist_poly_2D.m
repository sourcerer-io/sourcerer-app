% Euclidean distance between polyhedra in 2D
% Section 8.2.1, Boyd & Vandenberghe "Convex Optimization"
% Joelle Skaf - 10/09/05
% (a figure is generated)
%
% Given two polyhedra C = {x | A1*x <= b1} and D = {x | A2*x <= b2}, the
% distance between them is the optimal value of the problem:
%           minimize    || x - y ||_2
%               s.t.    A1*x <= b1
%                       A2*y <= b2
% Note: here x is in R^2

% Input data
randn('seed',0);
n = 2;
m = 2*n;
A1 = randn(m,n);
b1 = randn(m,1);
A2 = randn(m,n);
b2 = randn(m,1);

fprintf(1,'Computing the distance between the 2 polyhedra...');
% Solution via CVX
cvx_begin
    variables x(n) y(n)
    minimize (norm(x - y))
    norm(x,1) <= 2;
    norm(y-[4;3],inf) <=1;
cvx_end

fprintf(1,'Done! \n');

% Displaying results
disp('------------------------------------------------------------------');
disp('The distance between the 2 polyhedra C and D is: ' );
disp(['dist(C,D) = ' num2str(cvx_optval)]);
disp('The optimal points are: ')
disp('x = '); disp(x);
disp('y = '); disp(y);

%Plotting
figure;
fill([-2; 0; 2; 0],[0;2;0;-2],'b', [3;5;5;3],[2;2;4;4],'r')
axis([-3 6 -3 6])
axis square
hold on;
plot(x(1),x(2),'k.')
plot(y(1),y(2),'k.')
plot([x(1) y(1)],[x(2) y(2)])
title('Euclidean distance between 2 polyhedron in R^2');
xlabel('x_1');
ylabel('x_2');
