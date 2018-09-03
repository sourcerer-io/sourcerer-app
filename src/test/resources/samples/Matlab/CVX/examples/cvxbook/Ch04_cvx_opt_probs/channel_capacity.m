% Exercise 4.57: Capacity of a communication channel 
% Boyd & Vandenberghe "Convex Optimization" 
% Joëlle Skaf - 04/24/08 
%
% We consider a discrete memoryless communication channel, with input 
% X(t) \in {1,...,n}, and output Y(t) \in {1,...,m}, for t = 1,2,...  
% The relation between the input and output is given statistically: 
%           p_ij = Prob(Y(t)=i|X(t)=j), i=1,...,m,  j=1,...,n
% The matrix P is called the channel transition matrix.
% The channel capacity C is given by 
%           C = sup{ I(X;Y) | x >= 0, sum(x) = 1}, 
% I(X;Y) is the mutual information between X and Y, and it can be shown 
% that:     I(X;Y) = c'*x - sum_{i=1}^m y_i*log_2(y_i)
% where     c_j = sum_{i=1}^m p_ij*log_2(p_ij), j=1,...,m

% Input data 
rand('state', 0); 
n = 15;
m = 10; 
P = rand(m,n); 
P = P./repmat(sum(P),m,1); 
c = sum(P.*log2(P))';

% Channel capacity 
cvx_begin
    variable x(n) 
    y = P*x; 
    maximize (c'*x + sum(entr(y))/log(2))
    x >= 0;
    sum(x) == 1; 
cvx_end
C = cvx_optval; 

% Results
display(['The channel capacity is: ' num2str(C) ' bits.'])

