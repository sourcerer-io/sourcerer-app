% Example 8.4: One free point localization
% Section 8.7.1, Boyd & Vandenberghe "Convex Optimization"
% Joelle Skaf - 10/23/05
%
% K fixed points (u1,v1),..., (uK,vK) in R^2 are given and the goal is to place
% one additional point (u,v) such that:
% 1) the L1-norm is minimized, i.e.
%           minimize    sum_{i=1}^K ( |u - u_i| + |v - v_i| )
%    the solution in this case is any median of the fixed points
% 2) the L2-norm is minimized, i.e.
%           minimize    sum_{i=1}^K ( |u - u_i|^2 + |v - v_i|^2 )^.5
%    the solution in this case is the Weber point of the fixed points

% Data generation
n = 2;
K = 11;
randn('state',0);
P = randn(n,K);

% L1 - norm
fprintf(1,'Minimizing the L1-norm of the sum of the distances to fixed points...');

cvx_begin
    variable x1(2)
    minimize ( sum(norms(x1*ones(1,K) - P,1)) )
cvx_end

fprintf(1,'Done! \n');

% L2 - norm
fprintf(1,'Minimizing the L2-norm of the sum of the distances to fixed points...');

cvx_begin
    variable x2(2)
    minimize ( sum(norms(x2*ones(1,K) - P,2)) )
cvx_end

fprintf(1,'Done! \n');

% Displaying results
disp('------------------------------------------------------------------');
disp('The optimal point location for the L1-norm case is: ');
disp(x1);
disp('The optimal point location for the L2-norm case is: ');
disp(x2);
