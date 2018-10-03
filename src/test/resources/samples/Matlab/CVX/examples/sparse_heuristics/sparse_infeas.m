% Finding a point that satisfies many linear inequalities
% Section 11.4.1, Boyd & Vandenberghe "Convex Optimization"
% Written for CVX by Almir Mutapcic - 02/18/06
%
% We consider a set of linear inequalities A*x <= b which are
% infeasible. Here A is a matrix in R^(m-by-n) and b belongs
% to R^m. We apply a heuristic to find a point x that violates
% only a small number of inequalities.
%
% We use the sum of infeasibilities heuristic:
%
%   minimize   sum( max( Ax - b ) )
%
% which is equivalent to the following LP (book pg. 580):
%
%   minimize   sum( s )
%       s.t.   Ax <= b + s
%              s >= 0
%
% with variables x in R^n and s in R^m.

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

% sum of infeasibilities heuristic
cvx_begin
   variable x(n)
   minimize( sum( max( A*x - b, 0 ) ) )
cvx_end

% full LP version of the sum of infeasibilities heuristic
% cvx_begin
%   variables x(n) s(m)
%   minimize( sum( s ) )
%   subject to
%     A*x <= b + s;
%     s >= 0;
% cvx_end

% number of satisfied inequalities
nv = length( find( A*x > b ) );
fprintf(1,'\nFound an x that violates %d out of %d inequalities.\n',nv,m);
