% Section 4.5.4: Minimum spectral radius via Peron-Frobenius theory (GP)
% Boyd & Vandenberghe "Convex Optimization"
% Joelle Skaf - 01/29/06
% Updated to use CVX mode by Almir Mutapcic 02/08/06
%
% The goal is to minimize the spectral radius of a square matrix A
% which is elementwise nonnegative, Aij >= 0 for all i,j. In this
% case A has a positive real eigenvalue lambda_pf (the Perron-Frobenius
% eigenvalue) which is equal to the spectral radius, and thus gives
% the fastest decay rate or slowest growth rate.
% The problem of minimizing the Perron-Frobenius eigenvalue of A,
% possibly subject to posynomial inequalities in some underlying
% variable x can be posed as a GP (for example):
%
%   minimize   lambda_pf( A(x) )
%       s.t.   f_i(x) <= 1   for i = 1,...,p
%
% where matrix A entries are some posynomial functions of variable x,
% and f_i are posynomials.
%
% We consider a specific example in which we want to find the fastest
% decay or slowest growth rate for the bacteria population governed
% by a simple dynamic model (see page 166). The problem is a GP:
%   minimize   lambda
%       s.t.   b1*v1 + b2*v2 + b3*v3 + b4*v4 <= lambda*v1
%              s1*v1 <= lambda*v2
%              s2*v2 <= lambda*v3
%              s3*v3 <= lambda*v4
%              1/2 <= ci <= 2
%              bi == bi^{nom}*(c1/c1^{nom})^alpha_i*(c2/c2^{nom})^beta_i
%              si == si^{nom}*(c1/c1^{nom})^gamma_i*(c2/c2^{nom})^delta_i
%
% with variables bi, si, ci, vi, lambda.

% constants
c_nom = [1 1]';
b_nom = [2 3 2 1]';
alpha = [1 1 1 1]'; beta  = [1 1 1 1]';
s_nom = [1 1 3]';
gamma = [1 1 1]'; delta = [1 1 1]';

cvx_begin gp
  % optimization variables
  variables lambda b(4) s(3) v(4) c(2)

  % objective is the Perron-Frobenius eigenvalue
  minimize( lambda )
  subject to
    % inequality constraints
    b'*v      <= lambda*v(1);
    s(1)*v(1) <= lambda*v(2);
    s(2)*v(2) <= lambda*v(3);
    s(3)*v(3) <= lambda*v(4);
    [0.5; 0.5] <= c; c <= [2; 2];
    % equality constraints
    b == b_nom.*((ones(4,1)*(c(1)/c_nom(1))).^alpha).*...
                ((ones(4,1)*(c(2)/c_nom(2))).^beta);
    s == s_nom.*((ones(3,1)*(c(1)/c_nom(1))).^gamma).*...
                ((ones(3,1)*(c(2)/c_nom(2))).^delta);
cvx_end

% displaying results
disp(' ')
if lambda < 1
  fprintf(1,'The fastest decay rate of the bacteria population is %3.2f.\n', lambda);
else
  fprintf(1,'The slowest growth rate of the bacteria population is %3.2f.\n', lambda);
end
disp(' ')
fprintf(1,'The concentration of chemical 1 achieving this result is %3.2f.\n', c(1));
fprintf(1,'The concentration of chemical 2 achieving this result is %3.2f.\n', c(2));
disp(' ')

% construct matrix A
A = zeros(4,4);
A(1,:) = b';
A(2,1) = s(1);
A(3,2) = s(2);
A(4,3) = s(3);

% eigenvalues of matrix A
disp('Eigenvalues of matrix A are: ')
eigA = eig(A)
