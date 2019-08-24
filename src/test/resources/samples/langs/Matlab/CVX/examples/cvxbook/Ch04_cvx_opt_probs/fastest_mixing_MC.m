% Section 4.6.3: Find the fastest mixing Markov chain on a graph
% Boyd & Vandenberghe "Convex Optimization"
% Joëlle Skaf - 09/26/05
%
% The 'fastest mixing Markov chain problem' is to find a transition
% probability matrix P on a graph E that minimizes the mixing rate r, where
% r = max{ lambda_2, -lambda_n } with lambda_1>=...>=lambda_n being the
% eigenvalues of P.

% Generate input data
n = 5;
E = [0 1 0 1 1; ...
     1 0 1 0 1; ...
     0 1 0 1 1; ...
     1 0 1 0 1; ...
     1 1 1 1 0];

% Create and solve model
cvx_begin
    variable P(n,n) symmetric
    minimize(norm(P - (1/n)*ones(n)))
    P*ones(n,1) == ones(n,1);
    P >= 0;
    P(E==0) == 0;
cvx_end
e = flipud(eig(P));
r = max(e(2), -e(n));

% Display results
disp('------------------------------------------------------------------------');
disp('The transition probability matrix of the optimal Markov chain is: ');
disp(P);
disp('The optimal mixing rate is: ');
disp(r);
