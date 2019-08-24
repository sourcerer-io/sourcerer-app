%{
    Tests basis pursuit de-noising

    min_x ||x||_1
s.t.
    || A(x) - b || <= eps

The solvers solve a regularized version, using
    ||x||_1 + mu/2*||x-x_0||_2^2

This version allows for complex measurements.

see also test_sBPDN.m

%}

% Before running this, please add the TFOCS base directory to your path
myAwgn = @(x,snr) x + ...
        10^( (10*log10(sum(abs(x(:)).^2)/length(x(:))) - snr)/20 )*randn(size(x));

% Try to load the problem from disk
fileName = fullfile('reference_solutions','basispursuit_problem1_smoothed_noisy_complex');
randn('state',34324);
rand('state',34324);

N = 1024;
M = round(N/2);
K = round(M/5);

A = fft(eye(N));        % A is complex
rowsA = sort(randsample(N,M));
A = A(rowsA,:);
    
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
    % Note: with equality constraints, this is an LP, so for mu small
    % enough (but > 0), we have exact relaxation.

    % get reference via CVX
    tic
    cvx_begin
        cvx_precision best
        variable xcvx(N,1)
        minimize norm(xcvx,1) + mu/2*sum_square(xcvx-x0)
        subject to
            norm(A*xcvx - b ) <= EPS
    cvx_end
    time_IPM = toc;
    x_ref = xcvx;
    obj_ref = norm(x_ref,1) + mu/2*sum_square(x_ref-x0);
    
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
opts.errFcn     = { @(f,dual,primal) er(primal), ...
                    @(f,dual,primal) obj_ref - f  }; 
opts.maxIts     = 750;

% Option 1:
mode = 'r2c';
% mode = 'c2c';     % do NOT use this: it solves a different problem!
AA = A; bb = b; Ahandles = linop_matrix(AA,mode);

% Option 2:
% AA = [real(A); imag(A)]; bb = [real(b); imag(b)]; 
% Ahandles = linop_matrix(AA);

z0  = [];   % we don't have a good guess for the dual
tic;
[ x, out, optsOut ] = solver_sBPDN( Ahandles, bb, EPS, mu, x0, z0, opts );
time_TFOCS = toc;

fprintf('Solution has %d nonzeros.  Error vs. IPM solution is %.2e\n',...
    nnz(x), er(x) );

if out.err(end,1) < 1e-3
    disp('Everything is working');
else
    error('Failed the test');
end

% TFOCS v1.3 by Stephen Becker, Emmanuel Candes, and Michael Grant.
% Copyright 2013 California Institute of Technology and CVX Research.
% See the file LICENSE for full license information.
