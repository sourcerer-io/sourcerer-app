% Section 5.2.5: Mixed strategies for matrix games (LP formulation)
% Boyd & Vandenberghe, "Convex Optimization"
% Joëlle Skaf - 08/24/05
%
% Player 1 wishes to choose u to minimize his expected payoff u'Pv, while
% player 2 wishes to choose v to maximize u'Pv, where P is the payoff
% matrix, u and v are the probability distributions of the choices of each
% player (i.e. u>=0, v>=0, sum(u_i)=1, sum(v_i)=1)
% LP formulation:   minimize    t
%                       s.t.    u >=0 , sum(u) = 1, P'*u <= t*1
%                   maximize    t
%                       s.t.    v >=0 , sum(v) = 1, P*v >= t*1

% Input data
randn('state',0);
n = 12;
m = 12;
P = randn(n,m);

% Optimal strategy for Player 1
fprintf(1,'Computing the optimal strategy for player 1 ... ');

cvx_begin
    variables u(n) t1
    minimize ( t1 )
    u >= 0;
    ones(1,n)*u == 1;
    P'*u <= t1*ones(m,1);
cvx_end

fprintf(1,'Done! \n');

% Optimal strategy for Player 2
fprintf(1,'Computing the optimal strategy for player 2 ... ');

cvx_begin
    variables v(m) t2
    maximize ( t2 )
    v >= 0;
    ones(1,m)*v == 1;
    P*v >= t2*ones(n,1);
cvx_end

fprintf(1,'Done! \n');

% Displaying results
disp('------------------------------------------------------------------------');
disp('The optimal strategies for players 1 and 2 are respectively: ');
disp([u v]);
disp('The expected payoffs for player 1 and player 2 respectively are: ');
[t1 t2]
disp('They are equal as expected!');

