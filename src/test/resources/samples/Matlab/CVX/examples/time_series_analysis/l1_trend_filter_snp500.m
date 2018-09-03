% l1 trend filtering
% Written for CVX by Kwangmoo Koh - 12/10/07
%
% The problem of estimating underlying trends in time series data arises in
% a variety of disciplines. The l1 trend filtering method produces trend 
% estimates x that are piecewise linear from the time series y.
%
% The l1 trend estimation problem can be formulated as
%
%    minimize    (1/2)*||y-x||^2+lambda*||Dx||_1,
%
% with variable x , and problem data y and lambda, with lambda >0.
% D is the second difference matrix, with rows [0... -1 2 -1 ...0]
%
% CVX is not optimized for the l1 trend filtering problem.
% For large problems, use l1_tf (www.stanford.edu/~boyd/l1_tf/).

% load time series data
y = csvread('snp500.txt'); % log price of snp500
n = length(y);

% form second difference matrix
e = ones(n,1);
D = spdiags([e -2*e e], 0:2, n-2, n);

% set regularization parameter
lambda = 50;

% solve l1 trend filtering problem
cvx_begin
    variable x(n)
    minimize( 0.5*sum_square(y-x)+lambda*norm(D*x,1) )
cvx_end

% plot estimated trend with original signal
figure(1);
plot(1:n,y,'k:','LineWidth',1.0); hold on;
plot(1:n,x,'b-','LineWidth',2.0); hold off;
xlabel('date'); ylabel('log price');
