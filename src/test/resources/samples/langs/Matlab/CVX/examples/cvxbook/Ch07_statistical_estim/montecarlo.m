function prob = montecarlo(A,b,Sigma,notrials);

% Probability estimate using Monte Carlo methods
%
% Estimates the probability that a random vector x in R2
% with mean zero and covariance Sigma satisfies Ax <= b,
% based on 100 * notrials trials. Sigma must be PSD.

m = size(A,1);

R = chol(Sigma);   % Y = R^{-T}X has covariance I
X = R'*randn(2,notrials);
prob = length(find(sum(A*X - b(:,ones(1,notrials)) < 0) == m))/notrials;

for i=1:99
X = R'*randn(2,notrials);
prob = 0.5*(prob + ...
  length(find(sum(A*X - b(:,ones(1,notrials)) < 0) == m))/notrials);
end;

