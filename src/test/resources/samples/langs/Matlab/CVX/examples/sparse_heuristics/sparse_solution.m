% Computing a sparse solution of a set of linear inequalities
% Section 6.2, Boyd & Vandenberghe "Convex Optimization"
% "Just relax: Convex programming methods for subset selection
%  and sparse approximation" by J. A. Tropp
% Written for CVX by Almir Mutapcic - 02/28/06
%
% We consider a set of linear inequalities A*x <= b which are
% feasible. We apply two heuristics to find a sparse point x that
% satisfies these inequalities.
%
% The (standard) l1-norm heuristic for finding a sparse solution is:
%
%   minimize   ||x||_1
%       s.t.   Ax <= b
%
% The log-based heuristic is an iterative method for finding
% a sparse solution, by finding a local optimal point for the problem:
%
%   minimize   sum(log( delta + |x_i| ))
%       s.t.   Ax <= b
%
% where delta is a small threshold value (determines what is close to zero).
% We cannot solve this problem since it is a minimization of a concave
% function and thus it is not a convex problem. However, we can apply
% a heuristic in which we linearize the objective, solve, and re-iterate.
% This becomes a weighted l1-norm heuristic:
%
%   minimize sum( W_i * |x_i| )
%       s.t. Ax <= b
%
% which in each iteration re-adjusts the weights W_i based on the rule:
%
%   W_i = 1/(delta + |x_i|), where delta is a small threshold value
%
% This algorithm is described in papers:
% "An Affine Scaling Methodology for Best Basis Selection"
%  by B. D. Rao and K. Kreutz-Delgado
% "Portfolio optimization with linear and ям?xed transaction costs"
%  by M. S. Lobo, M. Fazel, and S. Boyd

% fix random number generator so we can repeat the experiment
seed = 0;
randn('state',seed);
rand('state',seed);

% the threshold value below which we consider an element to be zero
delta = 1e-8;

% problem dimensions (m inequalities in n-dimensional space)
m = 100;
n = 50;

% construct a feasible set of inequalities
% (this system is feasible for the x0 point)
A  = randn(m,n);
x0 = randn(n,1);
b  = A*x0 + rand(m,1); 

% l1-norm heuristic for finding a sparse solution
fprintf(1, 'Finding a sparse feasible point using l1-norm heuristic ...')
cvx_begin
  variable x_l1(n)
  minimize( norm( x_l1, 1 ) )
  subject to
    A*x_l1 <= b;
cvx_end

% number of nonzero elements in the solution (its cardinality or diversity)
nnz = length(find( abs(x_l1) > delta ));
fprintf(1,['\nFound a feasible x in R^%d that has %d nonzeros ' ...
           'using the l1-norm heuristic.\n'],n,nnz);

% iterative log heuristic
NUM_RUNS = 15;
nnzs = [];
W = ones(n,1); % initial weights

disp([char(10) 'Log-based heuristic:']);
for k = 1:NUM_RUNS
  cvx_begin quiet
    variable x_log(n)
    minimize( sum( W.*abs(x_log) ) )
    subject to
      A*x_log <= b;
  cvx_end

  % display new number of nonzeros in the solution vector
  nnz = length(find( abs(x_log) > delta ));
  nnzs = [nnzs nnz];
  fprintf(1,'   found a solution with %d nonzeros...\n', nnz);

  % adjust the weights and re-iterate
  W = 1./(delta + abs(x_log));
end

% number of nonzero elements in the solution (its cardinality or diversity)
nnz = length(find( abs(x_log) > delta ));
fprintf(1,['\nFound a feasible x in R^%d that has %d nonzeros ' ...
           'using the log heuristic.\n'],n,nnz);

% plot number of nonzeros versus iteration
plot(1:NUM_RUNS, nnzs, [1 NUM_RUNS],[nnzs(1) nnzs(1)],'--');
axis([1 NUM_RUNS 0 n])
xlabel('iteration'), ylabel('number of nonzeros (cardinality)');
legend('log heuristic','l1-norm heuristic','Location','SouthEast')
