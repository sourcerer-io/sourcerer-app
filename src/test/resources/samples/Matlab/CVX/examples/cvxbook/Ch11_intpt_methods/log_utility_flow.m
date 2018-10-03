% Section 11.8.4: Network rate optimization
% Boyd & Vandenberghe "Convex Optimization" 
% Argyrios Zymnis - 05/03/08
%
% We consider a network with n flows and L links. Each flow i,
% moves along a fixed predetermined path (i.e. a subset of the links)
% and has an associated rate x_i. Each link j has an associated capacity
% c_j. The total rate of all flows travelling along a link cannot exceed
% the link capacity. We can describe these link capacity limits using the
% flow-link incidence matrix A \in \reals^{L \times n}, where
% A_{ij} = 1, if flow j passes through link i and 0 otherwise.
% The link capacity constraints can be expressed as A*x <= c
% In the network rate problem the variables are the flow rates x. The
% objective is to choose the flow rates to maximize a separate utility
% function U, given by
%           U(x) = U_1(x_1)+U_2(x_2)+...+U_n(x_n)
% The network rate optimization problem is then
%           maximize    U(x)
%           subject to  A*x <= c
% Here we use U_i(x_i) = log x_i for all i

% Input data
rand('state',1)
L = 20;
n = 10;
k = 7; %average links per flow
A = double(rand(L,n) <= k/L);
c = 0.9*rand(L,1)+0.1;

% Solve network rate problem
cvx_begin
    variable x(n);
    maximize(sum(log(x)))
    subject to
        A*x <= c
cvx_end
primal_obj = cvx_optval;

% Solve dual problem to obtain link prices
cvx_begin
    variable lambda(L);
    minimize(c'*lambda-sum(log(A'*lambda))-n)
    subject to
        lambda >= 0
cvx_end
dual_obj = cvx_optval;
