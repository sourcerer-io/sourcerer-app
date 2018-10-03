%{
    Tests basis pursuit de-noising

    min_x ||x||_1
s.t.
    || A(x) - b || <= eps

The solvers solve a regularized version, using
    ||x||_1 + mu/2*||x-x_0||_2^2

in this file, we will use continuation to eliminate
the effect of the "mu" term.

see also test_sBPDN.m

%}

% Before running this, please add the TFOCS base directory to your path

% Try to load the problem from disk
fileName = fullfile('reference_solutions','basispursuit_problem1_noisy');
randn('state',34324);
rand('state',34324);
N = 1024;
M = round(N/2);
K = round(M/5);
A = randn(M,N);
myAwgn = @(x,snr) x + ...
        10^( (10*log10(sum(abs(x(:)).^2)/length(x(:))) - snr)/20 )*randn(size(x));
if exist([fileName,'.mat'],'file')
    load(fileName);
    fprintf('Loaded problem from %s\n', fileName );
else
    
    % Generate a new problem
    x = zeros(N,1);
    T = randsample(N,K);
    x(T) = randn(K,1);

    b_original = A*x;
    snr = 30;  % SNR in dB
    b   = myAwgn(b_original,snr);
    EPS = norm(b-b_original);
    x_original = x;
    
    mu = .01*norm(x,Inf);
    x0 = zeros(N,1);

    % get reference via CVX
    tic
    cvx_begin
        cvx_precision best
        variable xcvx(N,1)
        minimize norm(xcvx,1)
        subject to
            norm(A*xcvx - b ) <= EPS
    cvx_end
    time_IPM = toc;
    x_ref = xcvx;
    obj_ref = norm(x_ref,1);
    
    save(fileName,'x_ref','b','x_original','mu',...
        'EPS','b_original','obj_ref','x0','time_IPM','snr');
    fprintf('Saved data to file %s\n', fileName);
    
end


[M,N]           = size(A);
K               = nnz(x_original);
norm_x_ref      = norm(x_ref);
norm_x_orig     = norm(x_original);
er_ref          = @(x) norm(x-x_ref)/norm_x_ref;
er_signal       = @(x) norm(x-x_original)/norm_x_orig;
resid           = @(x) norm(A*x-b)/norm(b);  % change if b is noisy

fprintf('\tA is %d x %d, original signal has %d nonzeros\n', M, N, K );
fprintf('\tl1-norm solution and original signal differ by %.2e (mu = %.2e)\n', ...
    norm(x_ref - x_original)/norm(x_original),mu );

%% Call the TFOCS solver
er              = er_ref;  % error with reference solution (from IPM)
opts = [];
opts.restart    = 500;
opts.errFcn     = { @(f,dual,primal) er(primal) };
opts.maxIts     = 1000;
opts.countOps   = true;
% To see more possible options, run the command "tfocs"

z0  = [];   % we don't have a good guess for the dual
tic;


% -- with continuation:
opts.continuation   = true;

% when using continuation, a good stopping criteria is this one:
opts.stopCrit   = 4;  opts.tol  = 1e-6;
opts.printStopcrit = 1; % this will display the value used in the stopping criteria calculation
[ x, out, optsOut ] = solver_sBPDN( A, b, EPS, mu, x0, z0, opts);



time_TFOCS = toc;

fprintf('Solution has %d nonzeros.  Error vs. IPM solution is %.2e\n',...
    nnz(x), er(x) );
% Test we are within bounds:
if out.err(end,1) < 1e-3
    disp('Everything is working');
else
    error('Failed the test');
end
%% Advanced options for continuation
% To see all possible options, run "continuation" with no inputs:
continuation()

continuationOptions     = [];

% for example, we can make sure that we only take at most 200
%   iterations (except for the very last outer iteration):
continuationOptions.innerMaxIts     = 200;

% and instead of just 3 iterations (the default), let's do 5 iterations:
continuationOptions.maxIts          = 5;

% and decrease the tolerance of the outer loop
continuationOptions.tol             = 1e-5;

opts.printEvery                     = Inf;  % to suppress output from inner iterations
continuationOptions.verbose         = true; % "true" by default

% if you want mu to decrease:
continuationOptions.muDecrement     = 0.8;

[ x, out, optsOut ] = solver_sBPDN( A, b, EPS, mu, x0, z0, opts, continuationOptions);

% Test we are within bounds:
if out.err(end,1) < 1e-3
    disp('Everything is working');
else
    error('Failed the test');
end

% TFOCS v1.3 by Stephen Becker, Emmanuel Candes, and Michael Grant.
% Copyright 2013 California Institute of Technology and CVX Research.
% See the file LICENSE for full license information.
