%{
    Tests non-negative basis pursuit

    min_x ||X||_1
s.t.
    || A(X) - b|| <= eps  and x >= 0

The solvers solve a regularized version, using
||x||_1 + mu/2*||x-x_0||_2^2


See also test_sBPDN.m and test_sBP_nonnegative.m

%}

% Before running this, please add the TFOCS base directory to your path

% Try to load the problem from disk
fileName = fullfile('reference_solutions','basispursuit_problem1_smoothed_noisy_nonnegative');
randn('state',25442);
rand('state',2452);

N = 1024;
M = round(N/2);
K = round(M/2);

A = randn(M,N);
if exist([fileName,'.mat'],'file')
    load(fileName);
    fprintf('Loaded problem from %s\n', fileName );
else
    
    % Generate a new problem

    x = zeros(N,1);
    T = randsample(N,K);
    x(T) = .1+rand(K,1);  % x >= 0

    b = A*x;
    noise   = .1*norm(b)*randn(M,1)/sqrt(M);
    EPS = .9*norm(noise);
    b_original = b + noise;
    x_original = x;
    
    mu = .01*norm(x,Inf);
    x0 = zeros(N,1);

    % get reference via CVX
    tic
    cvx_begin
        cvx_precision best
        variable xcvx(N,1)
        minimize norm(xcvx,1) + mu/2*sum_square(xcvx-x0)
        subject to
            norm( A*xcvx - b ) <= EPS
            xcvx >= 0
    cvx_end
    time_IPM = toc;
    x_ref = xcvx;     
    obj_ref = norm(x_ref,1) + mu/2*sum_square(x_ref-x0);
    
    % get reference via CVX, this time, without the x >= 0 constraing
    tic
    cvx_begin
        cvx_precision best
        variable xcvx(N,1)
        minimize norm(xcvx,1) + mu/2*sum_square(xcvx-x0)
        subject to
            norm( A*xcvx - b ) <= EPS
    cvx_end
    time_IPM = toc;
    x_pureBP = xcvx;
    obj_ref = norm(x_ref,1) + mu/2*sum_square(x_ref-x0);
    
    save(fileName,'x_ref','b','x_original','mu',...
        'EPS','b_original','obj_ref','x0','time_IPM','x_pureBP');
    fprintf('Saved data to file %s\n', fileName);
    
end


[M,N]           = size(A);
K               = nnz(x_original);
norm_x_ref      = norm(x_ref);
norm_x_orig     = norm(x_original);
norm_x_pureBP   = norm(x_pureBP);
er_ref          = @(x) norm(x-x_ref)/norm_x_ref;        % err w.r.t. CVX
er_pureBP       = @(x) norm(x-x_pureBP)/norm_x_pureBP;  % err w.r.t. CVX w.o. nonneg constraint
er_signal       = @(x) norm(x-x_original)/norm_x_orig;  % err w.r.t. signal
resid           = @(x) norm(A*x-b)/norm(b);  % change if b is noisy

fprintf('\tA is %d x %d, original signal has %d nonzeros\n', M, N, K );
fprintf('\tl1-norm solution and original signal differ by:\t\t\t\t%.2e (mu = %.2e)\n', ...
    norm(x_pureBP - x_original)/norm(x_original),mu );
fprintf('\tl1-norm solution, with x >=0 constraint, and original signal differ by:\t%.2e (mu = %.2e)\n', ...
    norm(x_ref - x_original)/norm(x_original),mu );

disp('Note: because of the noise, we do not expect to get zero error');

%% Call the TFOCS solver
er              = er_ref;  % error with reference solution (from CVX)
opts = [];
% To see all possible options, run "tfocs()"
opts.errFcn     = { @(f,dual,primal) er(primal), ...
                    @(f,dual,primal) obj_ref - f, ...
                    @(f,dual,primal) nnz(primal) }; 
opts.maxIts     = 400;
z0  = [];   % we don't have a good guess for the dual

opts.nonneg     = true;     % tell it to add the x >= 0 constraint

tic;
x   = solver_sBPDN( A, b, EPS, mu, x0, z0, opts );
time_TFOCS = toc;

fprintf('for (original signal, IPM solution, TFOCS solution),\n   NNZ:\n\t%d\t\t%d\t\t%d\n',...
    nnz(x_original),nnz(x_ref), nnz(x) );
fprintf('   error vs. original, rel. l2 norm:\n\t%.2e\t%.2e\t%.2e\n',...
    0, er_signal(x_ref), er_signal(x) );
er_signal1 = @(x) norm(x-x_original,Inf);
fprintf('   error vs. original, lInf norm:\n\t%.2e\t%.2e\t%.2e\n',...
    0, er_signal1(x_ref), er_signal1(x) );
fprintf('   time to solve:\n\tN/A\t\t%.1fs\t\t%.1fs\n',...
    time_IPM, time_TFOCS );

% Check that we are within allowable bounds
if er(x) < .01
    disp('Everything is working');
else
    error('Failed the test');
end


% TFOCS v1.3 by Stephen Becker, Emmanuel Candes, and Michael Grant.
% Copyright 2013 California Institute of Technology and CVX Research.
% See the file LICENSE for full license information.
