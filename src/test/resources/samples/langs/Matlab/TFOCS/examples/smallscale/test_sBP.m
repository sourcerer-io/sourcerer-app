%{
    Tests basis pursuit

    min_x ||X||_1
s.t.
    A(X) == b

The solvers solve a regularized version, using
||x||_1 + mu/2*||x-x_0||_2^2

This problem is a linear program, so if mu is sufficiently small,
the smoothing has exactly no effect.

As a reference solution, we use either "x_ref" which is the interior-point
method solution, or we use "x_original", which is the original signal
used to generate the measurements b.  In general, "x_original" is not
the solution to the minimization problem; but under certain circumstances,
such as when "x_original" is very sparse, it is the solution to the minimization problem.
This is the fundamental result from compressed sensing.
When this situation applies, "x_original" is the correct solution to machine precision,
and will be more accurate than even "x_ref".

%}

% Before running this, please add the TFOCS base directory to your path

% Try to load the problem from disk
fileName = fullfile('reference_solutions','basispursuit_problem1_smoothed_noiseless');
randn('state',34324);

% We don't want to store "A"
rand('state',34324);
N = 1024;
M = round(N/2);
K = round(M/5);
A = randn(M,N);
if exist([fileName,'.mat'],'file')
    load(fileName);
    fprintf('Loaded problem from %s\n', fileName );
else
    % Generate a new problem
    x = zeros(N,1);
    T = randsample(N,K);
    x(T) = randn(K,1);

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
    cvx_end
    time_IPM = toc;
    x_ref = xcvx;      
    obj_ref = norm(x_ref,1) + mu/2*sum_square(x_ref-x0);
    
    save(fileName,'x_ref','b','x_original','mu',...
        'EPS','b_original','obj_ref','x0','time_IPM');
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
% er              = er_ref;  % error with reference solution (from IPM)
er              = er_signal; % error from original signal
% obj_ref         = norm(x_ref,1) + mu/2*norm(x_ref-x0)^2;
obj_ref           = norm(x_original,1) + mu/2*norm(x_original-x0)^2;
opts = [];
opts.errFcn     = { @(f,dual,primal) er(primal), ...
                    @(f,dual,primal) obj_ref - f  }; 
z0  = [];   % we don't have a good guess for the dual
tic;
[ x, out, optsOut ] = solver_sBP( A, b, mu, x0, z0, opts );
time_TFOCS = toc;

fprintf('--------------------------------------------------------\n');
fprintf('Results:\n-original signal-\t-IPM solution-  -TFOCS solution-\n');
fprintf('---------------------+-----------------+----------------\n');
fprintf('Number of nonzeros:\n\t%d\t\t%d\t\t%d\n',...
    nnz(x_original),nnz(x_ref), nnz(x) );
fprintf('Error vs. original, rel. l2 norm:\n\tN/A\t\t%.2e\t%.2e\n',...
    er_signal(x_ref), er_signal(x) );
er_signal1 = @(x) norm(x-x_original,Inf);
fprintf('Error vs. original, lInf norm:\n\tN/A\t\t%.2e\t%.2e\n',...
    er_signal1(x_ref), er_signal1(x) );
fprintf('Time to solve:\n\tN/A\t\t%.1fs\t\t%.1fs\n',...
    time_IPM, time_TFOCS );
fprintf('--------------------------------------------------------\n');

% Check that we are within allowable bounds
if out.err(end,1) < 1e-8
    disp('Everything is working');
else
    error('Failed the test');
end
%% Here is how you can view the error history on a graph
figure();
semilogy( out.err(:,1) );
xlabel('iterations'); ylabel('error');

%% Here are some alternative ways to call it
opts = [];
opts.maxIts     = 500;

A_TFOCS = linop_matrix( A );    % not necessary, but one way to do it
[ x, out, optsOut ] = solver_sBP( A_TFOCS, b, mu, x0, z0, opts );

% We can also pass in function handles
Af  = @(x) A*x;
At  = @(y) A'*y;
A_TFOCS = linop_handles( [M,N], Af, At );
[ x, out, optsOut ] = solver_sBP( A_TFOCS, b, mu, x0, z0, opts );

%% close plots
close all

% TFOCS v1.3 by Stephen Becker, Emmanuel Candes, and Michael Grant.
% Copyright 2013 California Institute of Technology and CVX Research.
% See the file LICENSE for full license information.
