%{
    Tests two common block norms

    min_X ||X||_{1,p}
s.t.
    || A(X) - b || <= eps

where ||X||_{1,p} is sum_{i=1:m} norm(X(i,:),p)
and X is a m x n matrix.  "p" is either 2 or Inf.
If n = 1, then for both p = 2 and p = Inf, this reduces
to the l1 norm.

We may think of the columns of X as a new signal.  The block
norm may be useful when we believe that these columns
are quite similar, e.g. when their supports overlap significantly.

see also test_sBPDN.m

%}
myAwgn = @(x,snr) x + ...
        10^( (10*log10(sum(abs(x(:)).^2)/length(x(:))) - snr)/20 )*randn(size(x));

% Before running this, please add the TFOCS base directory to your path

% Try to load the problem from disk
fileName = fullfile('reference_solutions','blocknorm_smoothed_noisy');
randn('state',34324);
rand('state',34324);
% N = 1024;
N = 128;
M = round(N/2);
K = round(M/5);
A = randn(M,N);
d = 10;  % number of columns of the signal matrix
if exist([fileName,'.mat'],'file')
    load(fileName);
    fprintf('Loaded problem from %s\n', fileName );
else
    
    % Generate a new problem
    % Our signal model is the following:
    %   for each column, half of the support (i.e. K/2 entries)
    %   is taken from the first 1:K elements, so these will likely
    %   have a strong overlap.
    %   The second half of the support is taken from the remaining
    %   elements, so will have less chance of overlap.
    % (May not be 1/2, but that's the rough idea)
    x = zeros(N,d);
    K2 = round(.6*K);
    for i = 1:d
        T1 = randsample(K,K2);
        T2 = randsample(N-K,K-K2) + K;
        x(T1,i) = randn(K2,1);
        x(T2,i) = randn(K-K2,1);
    end

    b_original = A*x;
    snr = 10;  % SNR in dB
    b   = myAwgn(b_original,snr);
    EPS = norm(b-b_original,'fro');
    x_original = x;
    err = @(X) norm(X-x_original,'fro')/norm(x_original,'fro');
    
    mu = .01*norm(x,Inf);
    x0 = zeros(N,d);

    % get reference via CVX
    
    % How would we do if we did the estimation separately?
    Xcvx_separate = zeros(N,d);
    for i = 1:d
      cvx_begin
        cvx_precision best
        cvx_quiet true
        variable xcvx(N,1)
        minimize norm(xcvx,1) + mu/2*sum_square(xcvx-x0(:,i) )
        subject to
            norm(A*xcvx - b(:,i) ) <= EPS/sqrt(d)
      cvx_end
      Xcvx_separate(:,i) = xcvx;
    end
    fprintf('Estimating each column separately, the error is %.2e\n',...
        err(Xcvx_separate) );
    
    
    % Now, use p = 2
    p = 2;
    dim = 2;
    cvx_begin
        cvx_precision best
        cvx_quiet true
        variable xcvx(N,d)
        minimize sum(norms(xcvx,p,dim)) + mu/2*pow_pos( norm(xcvx-x0,'fro'), 2)
        subject to
            norm(A*xcvx - b,'fro' ) <= EPS
    cvx_end
    Xcvx_p2 = xcvx;
    fprintf('Estimating using the block 1-2 norm, the error is %.2e\n',...
        err(Xcvx_p2) );
   
    % Now, use p = Inf
    p = Inf;
    dim = 2;
    cvx_begin
        cvx_precision best
        cvx_quiet true
        variable xcvx(N,d)
        minimize sum(norms(xcvx,p,dim)) + mu/2*pow_pos( norm(xcvx-x0,'fro'), 2)
        subject to
            norm(A*xcvx - b,'fro' ) <= EPS
    cvx_end
    Xcvx_pInf = xcvx;
    fprintf('Estimating using the block 1-Inf norm, the error is %.2e\n',...
        err(Xcvx_pInf) );
    
    
    save(fileName,'Xcvx_separate','Xcvx_p2','Xcvx_pInf','b','x_original','mu',...
        'EPS','b_original','x0','snr');
    fprintf('Saved data to file %s\n', fileName);
    
end

err = @(X) norm(X-x_original,'fro')/norm(x_original,'fro');
fprintf('Block norm estimation: the error between cvx solution and orignal signal is...\n');
fprintf('  Estimating each column separately, the error is %.2e\n',...
    err(Xcvx_separate) );
fprintf('  Estimating using the block 1-2 norm, the error is %.2e\n',...
    err(Xcvx_p2) );
fprintf('  Estimating using the block 1-Inf norm, the error is %.2e\n',...
    err(Xcvx_pInf) );

%% Call the TFOCS solver for each column separately
disp('-- Testing TFOCS against the IPM (CVX) solution, each column separately --');
X_separate = zeros(N,d);
for i = 1:d
    er              = @(x) norm(x-Xcvx_separate(:,i))/norm(Xcvx_separate(:,i));
    opts = [];
    opts.restart    = 500;
    opts.errFcn     = @(f,dual,primal) er(primal);
    opts.maxIts     = 1000;
    opts.tol        = 1e-8;
    opts.printEvery = 500;
    opts.fid        = 0;
    opts.restart    = 100;
    z0  = [];   % we don't have a good guess for the dual
    
    [ x, out, optsOut ] = solver_sBPDN( A, b(:,i), EPS/sqrt(d), mu, x0(:,i), z0, opts );
    
    fprintf('Error vs. IPM solution is %.2e\n',er(x) );
    X_separate(:,i) = x;
    
    % Check that we are within allowable bounds
    if er(x) > 1e-6
        error('Failed the test');
    end
end
fprintf('Overall error vs. IPM solution is %.2e\n',...
    norm(X_separate-Xcvx_separate,'fro')/norm(Xcvx_separate,'fro') );

%% Call the TFOCS solver for p = 2
disp('-- Testing TFOCS against the IPM (CVX) solution, block norm, p = 2 --');
er              = @(x) norm(x-Xcvx_p2,'fro')/norm(Xcvx_p2,'fro');
opts = [];
opts.restart    = 200;
opts.errFcn     = @(f,dual,primal) er(primal);
opts.maxIts     = 1000;
opts.tol        = 1e-8;
opts.printEvery = 50;
opts.fid        = 1;
z0  = [];   % we don't have a good guess for the dual

AA = A;  % doesn't work "out-of-the-box", because it thnkgs
         % the domain of A is N x 1 matrices (it's really N x d).
AA = linop_matrix(A, 'r2r',d );
[x,out,opts] = tfocs_SCD( prox_l1l2, { AA, -b }, prox_l2( EPS ), mu, x0, z0, opts );

fprintf('Error vs. IPM solution is %.2e\n',er(x) );

% Check that we are within allowable bounds
if er(x) < 5e-6
    disp('Everything is working');
else
    error('Failed the test');
end
%% Call the TFOCS solver for p = Inf
disp('-- Testing TFOCS against the IPM (CVX) solution, block norm, p = Inf --');
er              = @(x) norm(x-Xcvx_pInf,'fro')/norm(Xcvx_pInf,'fro');
opts = [];
opts.restart    = 200;
opts.errFcn     = @(f,dual,primal) er(primal);
opts.maxIts     = 1000;
opts.tol        = 1e-8;
opts.printEvery = 50;
opts.fid        = 1;
z0  = [];   % we don't have a good guess for the dual

AA = A;  % doesn't work "out-of-the-box", because it thnkgs
         % the domain of A is N x 1 matrices (it's really N x d).
AA = linop_matrix(A, 'r2r',d );
[x,out,opts] = tfocs_SCD( prox_l1linf(1), { AA, -b }, prox_l2( EPS ), mu, x0, z0, opts );

fprintf('Error vs. IPM solution is %.2e\n',er(x) );
if er(x) < 3e-6
    disp('Everything is working');
else
    error('Failed the test');
end

% TFOCS v1.3 by Stephen Becker, Emmanuel Candes, and Michael Grant.
% Copyright 2013 California Institute of Technology and CVX Research.
% See the file LICENSE for full license information.
