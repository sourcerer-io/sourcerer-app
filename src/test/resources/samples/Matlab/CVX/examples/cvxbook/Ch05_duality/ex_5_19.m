% Exercise 5.19c: Markovitz portfolio optimization w/ diversification constraint
% Boyd & Vandenberghe, "Convex Optimization"
% Joëlle Skaf - 08/29/05
%
% Solves an extension of the classical Markovitz portfolio optimization
% problem:      minimize    x'Sx
%                   s.t.    p_'*x >= r_min
%                           1'*x = 1,   x >= 0
%                           sum_{i=1}^{0.1*n}x[i] <= alpha
% where p_ and S are the mean and covariance matrix of the price range
% vector p, x[i] is the ith greatest component in x.
% The last constraint can be replaced by this equivalent set of constraints
%                           r*t + sum(u) <= alpha
%                           t*1 + u >= x
%                           u >= 0

% Input data
randn('state',0);
n = 25;
p_mean = randn(n,1);
temp = randn(n);
sig = temp'*temp;
r = floor(0.1*n);
alpha = 0.8;
r_min = 1;

% original formulation
fprintf(1,'Computing the optimal Markovitz portfolio: \n');
fprintf(1,'# using the original formulation ... ');

cvx_begin
    variable x1(n)
    minimize ( quad_form(x1,sig) )
    p_mean'*x1 >= r_min;
    ones(1,n)*x1 == 1;
    x1 >= 0;
    sum_largest(x1,r) <= alpha;
cvx_end

fprintf(1,'Done! \n');
opt1 = cvx_optval;

% equivalent formulation
fprintf(1,'# using an equivalent formulation by replacing the diversification\n');
fprintf(1,'  constraint by an equivalent set of linear constraints...');

cvx_begin
    variables x2(n) u(n) t(1)
    minimize ( quad_form(x2,sig) )
    p_mean'*x2 >= r_min;
    sum(x2) == 1;
    x2 >= 0;
    r*t + sum(u) <= alpha;
    t*ones(n,1) + u >= x2;
    u >= 0;
cvx_end

fprintf(1,'Done! \n');
opt2 = cvx_optval;

% Displaying results
disp('------------------------------------------------------------------------');
disp('The optimal portfolios obtained from the original problem formulation and');
disp('from the equivalent formulation are respectively: ');
disp([x1 x2])
disp('They are equal as expected!');
