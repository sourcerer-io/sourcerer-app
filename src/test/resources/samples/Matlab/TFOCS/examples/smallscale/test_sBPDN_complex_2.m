%{
    Tests basis pursuit de-noising

    min_x ||x||_1
s.t.
    || A(x) - b || <= eps

The solvers solve a regularized version, using
    ||x||_1 + mu/2*||x-x_0||_2^2

This version allows for complex measurements.

Unlike test_sBPDN_complex, we also allow x to be complex.
For example, suppose we have a signal f that is the superposition
of a few tones.  Then in the "synthesis" formulation, we make the
change-of-variables  x = F f, where F is the FFT matrix.
If "PHI" is the measurement matrix, then the linear operator is
A = Phi*F', where F' = inv(F) is the IFFT.

see also test_sBPDN.m, test_sBPDN_complex, test_sBPDN_W

%}

% Before running this, please add the TFOCS base directory to your path
myAwgn = @(x,snr) x + ...
        10^( (10*log10(sum(abs(x(:)).^2)/length(x(:))) - snr)/20 )*randn(size(x));

% Try to load the problem from disk
fileName = fullfile('reference_solutions','basispursuit_problem1_smoothed_noisy_complex_2');
randn('state',34324);
rand('state',34324);
N = 1024;
M = round(N/2);
M = round(M/5);
Phi = randn(M,N);
if exist([fileName,'.mat'],'file')
    load(fileName);
    fprintf('Loaded problem from %s\n', fileName );
    F   = fft(eye(N))/sqrt(N);
    A   = Phi * F';
else
    
    % Generate a new problem
    
    F   = fft(eye(N))/sqrt(N);
    A   = Phi * F';
    
    % introduce a sparsifying transform "W"
    f = zeros(N,1);
    % the signal x consists of several pure tones at random frequencies
    K = 5; %
    for k = 1:K
        f = f + randn()*sin( rand()*pi*(1:N) + 2*pi*rand() ).';
    end
    x = fft(f)/sqrt(N);


    b_original = A*x;
    snr = 30;  % SNR in dB
    b   = myAwgn(b_original,snr);
    EPS = norm(b-b_original);
    x_original = x;
    
    mu = .001*norm(x,Inf);
    x0 = zeros(N,1);

    % get reference via CVX
    tic
    cvx_begin
        cvx_precision best
        variable xcvx(N,1) complex
        minimize norm(xcvx,1) + mu/2*sum_square_abs(xcvx-x0)
        subject to
            norm(A*xcvx - b ) <= EPS
    cvx_end
    time_IPM = toc;
    x_ref = xcvx;
    obj_ref = norm(x_ref,1) + mu/2*sum_square_abs(x_ref-x0);
    
    save(fileName,'x_ref','b','x_original','mu',...
        'EPS','b_original','obj_ref','x0','time_IPM','snr');
    fprintf('Saved data to file %s\n', fileName);
    
end


[M,N]           = size(A);
norm_x_ref      = norm(x_ref);
norm_x_orig     = norm(x_original);
er_ref          = @(x) norm(x-x_ref)/norm_x_ref;
er_signal       = @(x) norm(x-x_original)/norm_x_orig;
resid           = @(x) norm(A*x-b)/norm(b);  % change if b is noisy

fprintf('\tA is %d x %d, original signal has %d nonzeros\n', M, N, nnz(x_original) );
fprintf('\tl1-norm solution and original signal differ by %.2e (mu = %.2e)\n', ...
    norm(x_ref - x_original)/norm(x_original),mu );

%% Call the TFOCS solver
er              = er_ref;  % error with reference solution (from IPM)
opts = [];
opts.errFcn     = { @(f,dual,primal) er(primal), ...
                    @(f,dual,primal) obj_ref - f  }; 
opts.maxIts     = 4500;
opts.printEvery = 50;
opts.tol        = 1e-8;

mode = 'c2c';
AA = A; bb = b; Ahandles = linop_matrix(AA,mode);

z0  = [];   % we don't have a good guess for the dual
tic;
[ x, out, optsOut ] = solver_sBPDN( Ahandles, bb, EPS, mu, x0, z0, opts );
time_TFOCS = toc;

fprintf('Solution has %d nonzeros.  Error vs. IPM solution is %.2e\n',...
    nnz(x), er(x) );

if out.err(end,1) < 1e-5
    disp('Everything is working');
else
    error('Failed the test');
end

% TFOCS v1.3 by Stephen Becker, Emmanuel Candes, and Michael Grant.
% Copyright 2013 California Institute of Technology and CVX Research.
% See the file LICENSE for full license information.
