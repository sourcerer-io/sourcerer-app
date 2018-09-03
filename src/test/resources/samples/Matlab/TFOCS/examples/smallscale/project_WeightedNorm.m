%{

It is very quick and basically closed-form to project onto ||x||_1

e.g. Proj_x0 = argmin_{ ||x||_1 <= 1 } 1/2|| x - x0 ||^2

but it is hard to project onto the set ||Wx||_1 <= 1, for general W
(i.e. non-invertible)

Here we show how to solve the weighted projection with an iterative method

%}

N  = 100;
x0 = randn(N,1);
W  = randn(2*N,N);
%% project x0 onto l1 ball, no weighting (easy: one-step)
tau     = .8*norm(x0,1);    % make sure x0 isn't already feasibly
projection = proj_l1(tau);
[value,projX]  = projection(x0,1);
fprintf('tau - ||x||_1 is %.2e\n', tau - norm(projX,1) );


%% project x0 onto l1 ball, with weighting (harder: iterate)
tau     = .92*norm(W*x0,1);

mu  = 1;                     % any value works
e   = abs(eig(W'*W)/mu);
L   = max(e);
strngCvxty  = min(e); 
opts = [];
opts.alg    = 'AT'; 
% opts.alg    = 'N83';
% opts.alg    = 'GRA';
opts.tol    = 1e-12;
opts.maxits = 500;

opts.L0     = L;
opts.Lexact = L; 
opts.mu     = strngCvxty;

% opts.beta   = 1;  % prevents backtracking
opts.printEvery = 5;

% opts.restart = 5;

p = prox_linf(tau);     % project onto the  ||z||_1 <= tau  ball
[projWX,outData,optsOut] = tfocs_SCD( [],W,p, mu, x0, [], opts );

fprintf('tau - ||Wx||_1 is %.2e, and x0 and projected version differ by %.2e\n', ...
    tau - norm(W*projWX,1), norm(x0-projWX)/norm(x0) );

% Check that we are within allowable bounds
if abs(tau - norm(W*projWX,1)) < 1e-10
    disp('Everything is working');
else
    error('Failed the test');
end

% TFOCS v1.3 by Stephen Becker, Emmanuel Candes, and Michael Grant.
% Copyright 2013 California Institute of Technology and CVX Research.
% See the file LICENSE for full license information.