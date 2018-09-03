% Section 7.1.1: Covariance estimation for Gaussian variables
% Boyd & Vandenberghe "Convex Optimization" 
% Joëlle Skaf - 04/24/08 
% 
% Suppose y \in\reals^n is a Gaussian random variable with zero mean and 
% covariance matrix R = \Expect(yy^T). We want to estimate the covariance 
% matrix R based on N independent samples y1,...,yN drawn from the 
% distribution, and using prior knowledge about R (lower and upper bounds 
% on R) 
%           L <= R <= U 
% Let S be R^{-1}. The maximum likelihood (ML) estimate of S is found 
% by solving the problem 
%           maximize    logdet(S) - tr(SY) 
%           subject to  U^{-1} <= S <= L^{-1} 
% where Y is the sample covariance of y1,...,yN. 

% Input data 
randn('state',0);
n = 10; 
N = 1000; 
tmp = randn(n); 
L = tmp*tmp'; 
tmp = randn(n);
U = L + tmp*tmp'; 
R = (L+U)/2; 
y_sample = sqrtm(R)*randn(n,N); 
Y = cov(y_sample'); 
Ui = inv(U); Ui = 0.5*(Ui+Ui');
Li = inv(L); Li = 0.5*(Li+Li');

% Maximum likelihood estimate of R^{-1} 
cvx_begin sdp
    variable S(n,n) symmetric 
    maximize( log_det(S) - trace(S*Y) );
    S >= Ui;
    S <= Li;
cvx_end
R_hat = inv(S);

