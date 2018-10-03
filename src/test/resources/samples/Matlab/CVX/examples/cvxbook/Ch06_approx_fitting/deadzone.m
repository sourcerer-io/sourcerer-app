% Section 6.1.2: Residual minimization with deadzone penalty
% Boyd & Vandenberghe "Convex Optimization"
% Joelle Skaf - 08/17/05
%
% The penalty function approximation problem has the form:
%               minimize    sum(deadzone(Ax - b))
% where 'deadzone' is the deadzone penalty function
%               deadzone(y) = max(abs(y)-1,0)

% Input data
randn('state',0);
m = 16; n = 8;
A = randn(m,n);
b = randn(m,1);

% deadzone penalty
% original formulation
fprintf(1,'Computing the optimal solution of the deadzone approximation problem: \n');

cvx_begin
    variable x(n)
    minimize( sum(max(abs(A*x-b)-1,0)) )
cvx_end

fprintf(1,'Done! \n');

% Compare
disp( sprintf( '\nResults:\n--------\nsum(max(abs(A*x-b)-1,0)): %6.4f\ncvx_optval: %6.4f\ncvx_status: %s\n', sum(max(abs(A*x-b)-1,0)), cvx_optval, cvx_status ) );
disp( 'Optimal vector:' );
disp( [ '   x     = [ ', sprintf( '%7.4f ', x ), ']' ] );
disp( 'Residual vector:' );
disp( [ '   A*x-b = [ ', sprintf( '%7.4f ', A*x-b ), ']' ] );
disp( ' ' );
