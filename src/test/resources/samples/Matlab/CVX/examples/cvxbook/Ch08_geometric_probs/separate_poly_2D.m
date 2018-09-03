% Section 8.2.2: Separating polyhedra in 2D
% Boyd & Vandenberghe "Convex Optimization"
% Joelle Skaf - 10/09/05
% (a figure is generated)
%
% If the two polyhedra C = {x | A1*x <= b1} and D = {y | A2*y <= b2} can be
% separated by a hyperplane, it will be of the  form
%           z'*x - z'*y >= -lambda'*b1 - mu'*b2 > 0
% where z, lambda and mu are the optimal variables of the problem:
%           maximize    -b1'*lambda - b2'*mu
%               s.t.    A1'*lambda + z = 0
%                       A2'*mu  - z = 0
%                       norm*(z) <= 1
%                       lambda >=0 , mu >= 0
% Note: here x is in R^2

% Input data
randn('seed',0);
n  = 2;
m = 2*n;
A1 = [1 1; 1 -1; -1 1; -1 -1];
A2 = [1 0; -1 0; 0 1; 0 -1];
b1 = 2*ones(m,1);
b2 = [5; -3; 4; -2];

% Solving with CVX
fprintf(1,'Finding a separating hyperplane between the 2 polyhedra...');

cvx_begin
    variables lam(m) muu(m) z(n)
    maximize ( -b1'*lam - b2'*muu)
    A1'*lam + z == 0;
    A2'*muu - z == 0;
    norm(z) <= 1;
    -lam <=0;
    -muu <=0;
cvx_end

fprintf(1,'Done! \n');

% Displaying results
disp('------------------------------------------------------------------');
disp('The distance between the 2 polyhedra C and D is: ' );
disp(['dist(C,D) = ' num2str(cvx_optval)]);

% Plotting
t = linspace(-3,6,100);
p = -z(1)*t/z(2) + (muu'*b2 - lam'*b1)/(2*z(2));
figure;
fill([-2; 0; 2; 0],[0;2;0;-2],'b', [3;5;5;3],[2;2;4;4],'r')
axis([-3 6 -3 6])
axis square
hold on;
plot(t,p)
title('Separating 2 polyhedra by a hyperplane');


