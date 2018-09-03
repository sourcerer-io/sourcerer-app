% Detecting a small subset of infeasible linear inequalities
% Section 5.8, Boyd & Vandenberghe "Convex Optimization"
% Written for CVX by Almir Mutapcic - 02/18/06
%
% We consider a set of linear inequalities A*x <= b which are
% infeasible. Here A is a matrix in R^(m-by-n) and b belongs
% to R^m. We apply a l1-norm heuristic to find a small subset
% of mutually infeasible inequalities from a larger set of
% infeasible inequalities. The heuristic finds a sparse solution
% to the alternative inequality system.
%
% Original system is A*x <= b and it alternative ineq. system is:
%
%   lambda >= 0,   A'*lambda == 0.   b'*lambda < 0
%
% where lambda in R^m. We apply the l1-norm heuristic:
%
%   minimize   sum( lambda )
%       s.t.   A'*lambda == 0
%              b'*lambda == -1
%              lambda >= 0
%
% Positive lambdas gives us a small subset of inequalities from
% the original set which are mutually inconsistent.

% problem dimensions (m inequalities in n-dimensional space)
m = 150;
n = 10;

% fix random number generator so we can repeat the experiment
seed = 0;
randn('state',seed);

% construct infeasible inequalities
A = randn(m,n);
b = randn(m,1);

fprintf(1, ['Starting with an infeasible set of %d inequalities ' ...
            'in %d variables.\n'],m,n);

% you can verify that the set is infeasible
% cvx_begin
%   variable x(n)
%   A*x <= b;
% cvx_end

% solve the l1-norm heuristic problem applied to the alternative system
cvx_begin
   variables lambda(m)
   minimize( sum( lambda ) )
   subject to
     A'*lambda == 0;
     b'*lambda == -1; 
     lambda >= 0;
cvx_end

% report the smaller set of mutually inconsistent inequalities
infeas_set = find( abs(b.*lambda) > sqrt(eps)/n );
disp(' ');
fprintf(1,'Found a smaller set of %d mutually inconsistent inequalities.\n',...
        length(infeas_set));
disp(' ');
disp('A smaller set of mutually inconsistent inequalities are the ones');
disp('with row indices:'), infeas_set'

% check that this set is infeasible
% cvx_begin
%    variable x_infeas(n)
%    A(infeas_set,:)*x_infeas <= b(infeas_set);
% cvx_end
