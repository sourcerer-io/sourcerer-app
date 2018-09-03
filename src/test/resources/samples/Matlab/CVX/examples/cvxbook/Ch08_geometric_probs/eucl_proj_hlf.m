% Euclidean projection on a halfspace
% Sec. 8.1.1, Boyd & Vandenberghe "Convex Optimization"
% Joelle Skaf - 10/04/05
%
% The projection of x0 on a halfspace C = {x | a'*x <= b} is given by
%           minimize || x - x0 ||^2
%               s.t.    a'*x <= b
% It is also given by P_C(x0) = x0 + (b - a'*x0)*a/||a||^2 if a'*x0 > b
%                           and x0                         if a'*x0 <=b

% Input data
randn('seed',0);
n  = 10;
a  = randn(n,1);
b  = randn(1);
x0 = randn(n,1);    % a'*x0 <=b
x1 = x0 + a;        % a'*x1 > b

% Analytical solution
fprintf(1,'Computing the analytical solution for the case where a^T*x0 <=b...');
pc_x0 = x0;
fprintf(1,'Done! \n');
fprintf(1,'Computing the analytical solution for the case where a^T*x0 > b...');
pc_x1 = x1 + (b - a'*x1)*a/norm(a)^2;
fprintf(1,'Done! \n');

% Solution via QP
fprintf(1,'Computing the solution of the QP for the case where a^T*x0 <=b...');
cvx_begin quiet
    variable xs0(n)
    minimize ( square_pos(norm(xs0 - x0)) )
    a'*xs0 <= b;
cvx_end
fprintf(1,'Done! \n');

fprintf(1,'Computing the solution of the QP for the case where a^T*x0 > b...');
cvx_begin quiet
    variable xs1(n)
    minimize ( square_pos(norm(xs1 - x1)) )
    a'*xs1 <= b;
cvx_end
fprintf(1,'Done! \n');

% Verification
disp('-----------------------------------------------------------------');
disp('Verifying that p_C(x0) and x0_star are equal in the case where a^T*x0 <=b');
disp(['||p_C(x0) - x0_star|| = ' num2str(norm(xs0 - pc_x0))]);
disp('Hence they are equal to working precision');
disp('Verifying that p_C(x1) and x1_star are equal in the case where a^T*x1 > b');
disp(['||p_C(x1) - x1_star|| = ' num2str(norm(xs1 - pc_x1))]);
disp('Hence they are equal to working precision');
