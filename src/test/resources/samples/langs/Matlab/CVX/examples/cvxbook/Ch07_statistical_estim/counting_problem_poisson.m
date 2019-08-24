% Section 7.1.1: Counting problems with Poisson distribution 
% Boyd & Vandenberghe "Convex Optimization" 
% Joëlle Skaf - 04/24/08 
%
% The random variable y is nonnegative and integer valued with a Poisson
% distribution with mean mu > 0. In a simple statistical model, the mean mu
% is modeled as an affine function of a vector u: mu = a'*u + b.
% We are given a number of observations which consist of pairs (u_i,y_i), 
% i = 1,..., m, where y_i is the observed value of y for which the value of
% the explanatory variable is u_i. We find a maximum likelihood estimate of
% the model parameters a and b from these data by solving the problem 
%           maximize    sum_{i=1}^m (y_i*log(a'*u_i + b) - (a'*u_i + b))
% where the variables are a and b. 

% Input data
rand('state',0);
n = 10; 
m = 100; 
atrue = rand(n,1); 
btrue = rand; 

u = rand(n,m);
mu = atrue'*u + btrue; 

% Generate random variables y from a Poisson distribution
% (The distribution is actually truncated at 10*max(mu) for simplicity)
L  = exp(-mu);
ns = ceil(max(10*mu));
y  = sum(cumprod(rand(ns,m))>=L(ones(ns,1),:));

% Maximum likelihood estimate of model parameters 
cvx_begin 
    variables a(n) b(1) 
    maximize sum(y.*log(a'*u+b) - (a'*u+b))
cvx_end    
