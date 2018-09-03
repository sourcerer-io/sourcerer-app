% Section 5.2.4: Solves a simple QCQP
% Boyd & Vandenberghe, "Convex Optimization"
% Joëlle Skaf - 08/23/05
%
% Solved a QCQP with 3 inequalities:
%           minimize    1/2 x'*P0*x + q0'*r + r0
%               s.t.    1/2 x'*Pi*x + qi'*r + ri <= 0   for i=1,2,3
% and verifies that strong duality holds.

% Input data
randn('state',13);
n = 6;
P0 = randn(n); P0 = P0'*P0 + eps*eye(n);
P1 = randn(n); P1 = P1'*P1;
P2 = randn(n); P2 = P2'*P2;
P3 = randn(n); P3 = P3'*P3;
q0 = randn(n,1); q1 = randn(n,1); q2 = randn(n,1); q3 = randn(n,1);
r0 = randn(1); r1 = randn(1); r2 = randn(1); r3 = randn(1);

fprintf(1,'Computing the optimal value of the QCQP and its dual... ');

cvx_begin
    variable x(n)
    dual variables lam1 lam2 lam3
    minimize( 0.5*quad_form(x,P0) + q0'*x + r0 )
    lam1: 0.5*quad_form(x,P1) + q1'*x + r1 <= 0;
    lam2: 0.5*quad_form(x,P2) + q2'*x + r2 <= 0;
    lam3: 0.5*quad_form(x,P3) + q3'*x + r3 <= 0;
cvx_end

obj1 = cvx_optval;
P_lam = P0 + lam1*P1 + lam2*P2 + lam3*P3;
q_lam = q0 + lam1*q1 + lam2*q2 + lam3*q3;
r_lam = r0 + lam1*r1 + lam2*r2 + lam3*r3;
obj2 = -0.5*q_lam'*inv(P_lam)*q_lam + r_lam;

fprintf(1,'Done! \n');

% Displaying results
disp('------------------------------------------------------------------------');
disp('The duality gap is equal to ');
disp(obj1-obj2)
