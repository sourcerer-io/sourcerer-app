% Exercise 4.3: Solve a simple QP with inequality constraints
% From Boyd & Vandenberghe, "Convex Optimization"
% Joëlle Skaf - 09/26/05
%
% Solves the following QP with inequality constraints:
%           minimize    1/2x'*P*x + q'*x + r
%               s.t.    -1 <= x_i <= 1      for i = 1,2,3
% Also shows that the given x_star is indeed optimal

% Generate data
P = [13 12 -2; 12 17 6; -2 6 12];
q = [-22; -14.5; 13];
r = 1;
n = 3;
x_star = [1;1/2;-1];

% Construct and solve the model
fprintf(1,'Computing the optimal solution ...');
cvx_begin
    variable x(n)
    minimize ( (1/2)*quad_form(x,P) + q'*x + r)
    x >= -1;
    x <=  1;
cvx_end
fprintf(1,'Done! \n');

% Display results
disp('------------------------------------------------------------------------');
disp('The computed optimal solution is: ');
disp(x);
disp('The given optimal solution is: ');
disp(x_star);

