%{
    Tests non-negative basis pursuit

    min_x ||X||_1
s.t.
    A(X) == b and x >= 0

The solvers solve a regularized version, using
||x||_1 + mu/2*||x-x_0||_2^2

%}

% Before running this, please add the TFOCS base directory to your path

% Try to load the problem from disk
fileName = fullfile('reference_solutions','basispursuit_problem1_smoothed_noiseless_nonnegative');
randn('state',34324);
rand('state',34324);

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
    x(T) = .1+rand(K,1);

    b = A*x;
    EPS = 0;
    b_original = b;
    x_original = x;
    
    mu = .01*norm(x,Inf);
    x0 = zeros(N,1);
    % Note: with equality constraints, this is an LP, so for mu small
    % enough (but > 0), we have exact relaxation.

    % get reference via CVX
    tic
    cvx_begin
        cvx_precision best
        variable xcvx(N,1)
        minimize norm(xcvx,1) + mu/2*sum_square(xcvx-x0)
        subject to
            A*xcvx == b
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
            A*xcvx == b
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
er_ref          = @(x) norm(x-x_ref)/norm_x_ref;
er_pureBP       = @(x) norm(x-x_pureBP)/norm_x_pureBP;
er_signal       = @(x) norm(x-x_original)/norm_x_orig;
resid           = @(x) norm(A*x-b)/norm(b);  % change if b is noisy

fprintf('\tA is %d x %d, original signal has %d nonzeros\n', M, N, K );
fprintf('\tl1-norm solution and original signal differ by:\t\t\t\t%.2e (mu = %.2e)\n', ...
    norm(x_pureBP - x_original)/norm(x_original),mu );
fprintf('\tl1-norm solution, with x >=0 constraint, and original signal differ by:\t%.2e (mu = %.2e)\n', ...
    norm(x_ref - x_original)/norm(x_original),mu );

%% Call the TFOCS solver
er              = er_ref;  % error with reference solution (from IPM)
% er              = er_signal; % error from original signal
% er              = er_pureBP; % the "pureBP" solution did not have x>=0
opts = [];
opts.errFcn     = { @(f,dual,primal) er(primal), ...
                    @(f,dual,primal) obj_ref - f, ...
                    @(f,dual,primal) nnz(primal) }; 
opts.restart    = 1000;
z0  = [];   % we don't have a good guess for the dual
tic;

projectionF     = {proj_Rn; proj_Rplus };

scaleA = 1/norm(A);
[x,out,optsOut] = tfocs_SCD( prox_l1, { linop_compose(A,scaleA), -b*scaleA; 1,0 }, projectionF, mu, x0, z0, opts );



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

% Test we are within bounds:
if out.err(end,1) < 1e-6
    disp('Everything is working');
else
    error('Failed the test');
end
%% As of version 1.0d, the solver_sBP.m file can handle x >= 0 constraints
% This version will be more efficient, since it calls a special
%   l1 + non-negative operator, rather than splitting it up.

opts.nonneg     = true;     % tell it to add the x >= 0 constraint
[x,out,optsOut]   = solver_sBP( A, b, mu, x0, z0, opts );

% Test we are within bounds:
if out.err(end,1) < 1e-5
    disp('Everything is working');
else
    error('Failed the test');
end

% TFOCS v1.3 by Stephen Becker, Emmanuel Candes, and Michael Grant.
% Copyright 2013 California Institute of Technology and CVX Research.
% See the file LICENSE for full license information.
