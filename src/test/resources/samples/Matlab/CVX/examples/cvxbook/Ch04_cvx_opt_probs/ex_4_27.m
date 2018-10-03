% Exercise 4.27: Matrix fractional minimization using second-order cone programming
% From Boyd & Vandenberghe, "Convex Optimization"
% Joëlle Skaf - 09/26/05
%
% Shows the equivalence of the following formulations:
% 1)        minimize    (Ax + b)'*inv(I + B*diag(x)*B')*(Ax + b)
%               s.t.    x >= 0
% 2)        minimize    (Ax + b)'*inv(I + B*Y*B')*(Ax + b)
%               s.t.    x >= 0
%                       Y = diag(x)
% 3)        minimize    v'*v + w'*inv(diag(x))*w
%               s.t.    v + Bw = Ax + b
%                       x >= 0
% 4)        minimize    v'*v + w'*inv(Y)*w
%               s.t.    Y = diag(x)
%                       v + Bw = Ax + b
%                       x >= 0

% Generate input data
randn('state',0);
m = 16; n = 8;
A = randn(m,n);
b = randn(m,1);
B = randn(m,n);

% Problem 1: original formulation
disp('Computing optimal solution for 1st formulation...');
cvx_begin
    variable x1(n)
    minimize( matrix_frac(A*x1 + b , eye(m) + B*diag(x1)*B') )
    x1 >= 0;
cvx_end
opt1 = cvx_optval;

% Problem 2: original formulation (modified)
disp('Computing optimal solution for 2nd formulation...');
cvx_begin
    variable x2(n)
    variable Y(n,n) diagonal
    minimize( matrix_frac(A*x2 + b , eye(m) + B*Y*B') )
    x2 >= 0;
    Y == diag(x2);
cvx_end
opt2 = cvx_optval;

% Problem 3: equivalent formulation (as given in the book)
disp('Computing optimal solution for 3rd formulation...');
cvx_begin
    variables x3(n) w(n) v(m)
    minimize( square_pos(norm(v)) + matrix_frac(w, diag(x3)) )
    v + B*w == A*x3 + b;
    x3 >= 0;
cvx_end
opt3 = cvx_optval;

% Problem 4: equivalent formulation (modified)
disp('Computing optimal solution for 4th formulation...');
cvx_begin
    variables x4(n) w(n) v(m)
    variable Y(n,n) diagonal
    minimize( square_pos(norm(v)) + matrix_frac(w, Y) )
    v + B*w == A*x4 + b;
    x4 >= 0;
    Y == diag(x4);
cvx_end
opt4 = cvx_optval;

% Display the results
disp('------------------------------------------------------------------------');
disp('The optimal value for each of the 4 formulations is: ');
[opt1 opt2 opt3 opt4]
disp('They should be equal!')

