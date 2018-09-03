%{
    Tests the extended "analysis" form of basis pursuit de-noising

    min_1 alpha*||W_1 x||_1 + beta*|| W_2 x ||_1
s.t.
    || A(x) - b || <= eps

The solvers solve a regularized version

see also test_sBP.m and test_sBPDN.m and test_sBPDN_W.m

%}

% Before running this, please add the TFOCS base directory to your path
myAwgn = @(x,snr) x + ...
        10^( (10*log10(sum(abs(x(:)).^2)/length(x(:))) - snr)/20 )*randn(size(x));

% Try to load the problem from disk
fileName = fullfile('reference_solutions','basispursuit_WW_problem1_smoothed_noisy');
randn('state',34324);
rand('state',34324);

N = 512;
M = round(N/2);
K = round(M/5);

A = randn(M,N);
x = zeros(N,1);

% introduce a sparsifying transform "W"
d  = round(4*N);     % redundant
Wf = @(x) dct(x,d);  % zero-padded DCT
downsample  = @(x) x(1:N,:);
Wt = @(y) downsample( idct(y) );    % transpose of W
W  = Wf(eye(N));     % make an explicit matrix for CVX

% and add another transform:
d2 = round(2*N);
W2 = randn(d2,N);
if exist([fileName,'.mat'],'file')
    load(fileName);
    fprintf('Loaded problem from %s\n', fileName );
else
    
    % Generate a new problem

    alpha = 1;
    beta = 2;
    
    % the signal x consists of several pure tones at random frequencies
    for k = 1:K
        x = x + randn()*sin( rand()*pi*(1:N) + 2*pi*rand() ).';
    end


    b_original = A*x;
    snr = 40;  % SNR in dB
    b   = myAwgn(b_original,snr);
    EPS = norm(b-b_original);
    x_original = x;
    
    mu = .01*norm(Wf(x),Inf);
    x0 = zeros(N,1);

    % get reference via CVX
    tic
    cvx_begin
        cvx_precision high
        variable xcvx(N,1)
        minimize alpha*norm(W*xcvx,1) + beta*norm(W2*xcvx,1) + ...
            mu/2*sum_square(xcvx-x0)
        subject to
            norm(A*xcvx - b ) <= EPS
    cvx_end
    time_IPM = toc;
    x_ref = xcvx; 
    objF        = @(x)alpha*norm(W*x,1) +beta*norm(W2*x,1)+ mu/2*norm(x-x0).^2;
    obj_ref     = objF(x_ref);
    
    save(fileName,'x_ref','b','x_original','mu',...
        'EPS','b_original','obj_ref','x0','time_IPM','snr',...
        'd','d2','alpha','beta');
    fprintf('Saved data to file %s\n', fileName);
    
end


[M,N]           = size(A);
norm_x_ref      = norm(x_ref);
norm_x_orig     = norm(x_original);
er_ref          = @(x) norm(x-x_ref)/norm_x_ref;
er_signal       = @(x) norm(x-x_original)/norm_x_orig;
resid           = @(x) norm(A*x-b)/norm(b);  % change if b is noisy

fprintf('\tA is %d x %d\n', M, N );
fprintf('\tl1-norm solution and original signal differ by %.2e (mu = %.2e)\n', ...
    norm(x_ref - x_original)/norm(x_original),mu );

%% Call the TFOCS solver
objF            = @(x)alpha*norm(W*x,1) +beta*norm(W2*x,1)+ mu/2*norm(x-x0).^2;
infeasF         = @(x)norm(A*x-b) - EPS;
er              = er_ref;  % error with reference solution (from IPM)
opts            = [];
opts.errFcn     = { @(f,dual,primal) er(primal), ...
                    @(f,dual,primal) obj_ref - f, ...
                    @(f,dual,primal) infeasF(primal) }; 
opts.maxIts     = 2000;
opts.tol        = 1e-10;
% opts.normA2     = norm(A*A');
% opts.normW2     = norm(W'*W);
z0  = [];   % we don't have a good guess for the dual
tic;
[ x, out, optsOut ] = solver_sBPDN_WW( A, alpha,W,beta,W2,b, EPS, mu, x0, z0, opts );
time_TFOCS = toc;
fprintf('x is sub-optimal by %.2e, and infeasible by %.2e\n',...
    objF(x) - obj_ref, infeasF(x) );

fprintf('Solution has %d nonzeros.  Error vs. IPM solution is %.2e\n',...
    nnz(x), er(x) );

% Check that we are within allowable bounds
if out.err(end,1) < 1e-3
    disp('Everything is working');
else
    error('Failed the test');
end

% TFOCS v1.3 by Stephen Becker, Emmanuel Candes, and Michael Grant.
% Copyright 2013 California Institute of Technology and CVX Research.
% See the file LICENSE for full license information.
