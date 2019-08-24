%{
    Tests the Dantzig Selector

    min_x ||x||_1
s.t.
    || D*A'*(A*x - b) || <= delta

The solvers solve a regularized version, using
    ||x||_1 + mu/2*||x-x_0||_2^2

see also test_sBPDN.m

%}

% Before running this, please add the TFOCS base directory to your path
myAwgn = @(x,snr) x + ...
        10^( (10*log10(sum(abs(x(:)).^2)/length(x(:))) - snr)/20 )*randn(size(x));

% Try to load the problem from disk
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
    
    % Generate a new problem

    normA2 = norm( (A'*A) )^2;
    x = zeros(N,1);
    T = randsample(N,K);
    x(T) = randn(K,1);


    b_original = A*x;
    snr = 30;  % SNR in dB
    b   = myAwgn(b_original,snr);
    z   = b - b_original;
    sigma = std(z);     % estimate of standard deviation

    % compute D and delta so that original signal is
    %   feasible with probability 1 - alpha
    alpha   = 0.1;
    Anorms  = sqrt(sum(A.^2))';
    nTrials = min(4*N,400);
    w       = randn(M,nTrials);
    supAtz  = sort(max( (A'*w) ./Anorms(:,ones(1,nTrials))));
    thresh  = supAtz(round(nTrials*(1-alpha)));  % empirical
    d       = thresh*sigma*Anorms;  % a vector, for Dantzig solvers
    if all(d > 1e-10)
        delta   = mean(d);
        D       = delta./d; % watch out for division by 0
    else
        D       = 1;
        delta   = 0;
    end
    normA2 = norm( diag(D)*(A'*A) )^2;
%     clear d alpha w thresh nTrials

    x_original = x;
    
    mu = .05*norm(x,Inf);
    x0 = zeros(N,1);
    % Note:this is an LP, so for mu small
    % enough (but > 0), we have exact relaxation.

    % get reference via CVX
    tic
    cvx_begin
        cvx_precision best
        variable xcvx(N,1)
        minimize norm(xcvx,1) + mu/2*sum_square(xcvx-x0)
        subject to
            norm(D.*(A'*(A*xcvx - b)),Inf ) <= delta
    cvx_end
    time_IPM = toc;
    x_ref = xcvx;
    obj_ref = norm(x_ref,1) + mu/2*sum_square(x_ref-x0);
    
    save(fileName,'x_ref','b','x_original','mu',...
        'delta','D','b_original','obj_ref','x0','time_IPM','snr');
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
opts.errFcn     = { @(f,dual,primal) er(primal), ...
                    @(f,dual,primal) obj_ref - f  }; 
opts.maxIts     = 2000;
z0  = [];   % we don't have a good guess for the dual
tic;
[ x, out, optsOut ] = solver_sDantzig( {A,D}, b, delta, mu, x0, z0, opts );
time_TFOCS = toc;

fprintf('Solution has %d nonzeros.  Error vs. IPM solution is %.2e\n',...
    nnz(x), er(x) );

% Check that we are within allowable bounds
if out.err(end,1) < 1e-4
    disp('Everything is working');
else
    error('Failed the test');
end
%% plot error
semilogy( out.err(:,1) )
hold all

%% Call the solver with W = I
%   This is not usually recommended, since it is not necessary
%   and creates extra dual variables
opts.restart    = 2000;
W = linop_scale(1); % identity
[ x, out, optsOut ] = solver_sDantzig_W( {A,D}, W, b, delta, mu, x0, z0, opts );
% Check that we are within allowable bounds
if out.err(end,1) < 1e-1
    disp('Everything is working');
else
    error('Failed the test');
end

%% close all figures
close all

% TFOCS v1.3 by Stephen Becker, Emmanuel Candes, and Michael Grant.
% Copyright 2013 California Institute of Technology and CVX Research.
% See the file LICENSE for full license information.
