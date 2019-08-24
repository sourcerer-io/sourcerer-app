%{
    Tests the Dantzig Selector

    min_x ||x||_1
s.t.
    || D*A'*(A*x - b) || <= delta

The solvers solve a regularized version, using
    ||x||_1 + mu/2*||x-x_0||_2^2

see also test_sDantzig.m

This demo shows three formulations of the Dantzig selector
Instead of calling a pre-built solver, we show how to call
tfocs_SCD directly.

%}

% Before running this, please add the TFOCS base directory to your path

% Try to load the problem from disk
mu = 0;
fileName = fullfile('reference_solutions','dantzig_problem1_smoothed_noisy');
randn('state',34324);
rand('state',34324);
N = 1024;
M = round(N/2);
K = round(M/5);
A = randn(M,N);
if exist([fileName,'.mat'],'file')
    load(fileName);
    fprintf('Loaded problem from %s\n', fileName );
else
    disp('Please run test_sDantzig.m to setup the file');
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
opts.errFcn     = { @(f,dual,primal) er(primal), ...
                    @(f,dual,primal) obj_ref - f  }; 
opts.maxIts     = 1000;
opts.printEvery = 100;
z0  = [];   % we don't have a good guess for the dual


%% Method 1: use the epigraph of the l_infinity norm as the cone
% Note: this is equivalent to calling:
% [ x, out, optsOut ] = solver_sDantzig( {A,D}, b, delta, mu, x0, z0, opts );

DAtb = D.*(A'*b);
DD = @(x) D.*(x);
objectiveF = prox_l1;
affineF     = {linop_matrix(diag(D)*(A'*A)), -DAtb };
dualproxF  = prox_l1( delta );
[ x, out, opts ] = tfocs_SCD( objectiveF, affineF, dualproxF, mu, x0, z0, opts );
x1 = x;
out1 = out;

fprintf('Solution has %d nonzeros.  Error vs. IPM solution is %.2e\n',...
    nnz(x), er(x) );

% Check that we are within allowable bounds
if out.err(end,1) < 1e-3
    disp('Everything is working');
else
    error('Failed the test');
end
%% Method 2: use the LP formulation
% Instead of the constraint ||Ax-b||_infty <= delta
% (where "A" is really DA'A),
% think of it as
% -(Ax-b) + delta >= 0
%  (Ax-b) + delta >= 0

objectiveF = prox_l1;
affineF     = {linop_matrix(-diag(D)*(A'*A)),  DAtb + delta;...
               linop_matrix( diag(D)*(A'*A)), -DAtb + delta; };

dualproxF  = { proj_Rplus; proj_Rplus };
[ x, out, opts ] = tfocs_SCD( objectiveF, affineF, dualproxF, mu, x0, z0, opts );
x2 = x;
out2 = out;

% Check that we are within allowable bounds
if out.err(end,1) < 1e-3
    disp('Everything is working');
else
    error('Failed the test');
end
%% Method 3: put objective into constraint
% This is the trick we do with solver_sDantzig_W, to deal with ||Wx||_1
% Instead of minimizing ||x||_1, we minimize t,
%   with the constraint that ||x||_1 <= t
% This version has some scaling considerations -- if we 
% are careful about scaling, the dual problem will be solved much faster.

% Note: we still have to deal with the original constraints.  We
% can use either method 1 or method 2 above.  Here, we'll use
% method 1.


objectiveF  = [];    % tfocs_SCD recognizes this special objective
normA2      = norm( diag(D)*A'*A )^2;
scale       = 1/sqrt(normA2);
affineF     = {linop_matrix(diag(D)*(A'*A)), -DAtb; linop_scale(1/scale), 0 };
dualproxF   = { prox_l1(delta); proj_linf(scale) };
[ x, out, opts ] = tfocs_SCD( objectiveF, affineF, dualproxF, mu, x0, z0, opts );
x3 = x;
out3 = out;

% Check that we are within allowable bounds
if out.err(end,1) < 1e-2
    disp('Everything is working');
else
    error('Failed the test');
end
%% plot
figure;
semilogy( out1.err(:,1) );
hold all
semilogy( out2.err(:,1) );
semilogy( out3.err(:,1) );
legend('Method 1 (epigraph cone)','Method 2 (LP)','Method 3 (W=I)' );

%% close all plots
close all


% TFOCS v1.3 by Stephen Becker, Emmanuel Candes, and Michael Grant.
% Copyright 2013 California Institute of Technology and CVX Research.
% See the file LICENSE for full license information.