% Section 5.2.5: Mixed strategies for matrix games
% Boyd & Vandenberghe "Convex Optimization"
% Joëlle Skaf - 08/24/05
%
% Player 1 wishes to choose u to minimize his expected payoff u'Pv, while
% player 2 wishes to choose v to maximize u'Pv, where P is the payoff
% matrix, u and v are the probability distributions of the choices of each
% player (i.e. u>=0, v>=0, sum(u_i)=1, sum(v_i)=1)

% Input data
randn('state',0);
n = 10;
m = 10;
P = randn(n,m);

% Optimal strategy for Player 1
fprintf(1,'Computing the optimal strategy for player 1 ... ');

cvx_begin
    variable u(n)
    minimize ( max ( P'*u) )
    u >= 0;
    ones(1,n)*u == 1;
cvx_end

fprintf(1,'Done! \n');
obj1 = cvx_optval;

% Optimal strategy for Player 2
fprintf(1,'Computing the optimal strategy for player 2 ... ');

cvx_begin
    variable v(m)
    maximize ( min (P*v) )
    v >= 0;
    ones(1,m)*v == 1;
cvx_end

fprintf(1,'Done! \n');
obj2 = cvx_optval;

% Displaying results
disp('------------------------------------------------------------------------');
disp('The optimal strategies for players 1 and 2 are respectively: ');
disp([u v]);
disp('The expected payoffs for player 1 and player 2 respectively are: ');
[obj1 obj2]
disp('They are equal as expected!');