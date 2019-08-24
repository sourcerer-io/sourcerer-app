%{
    Tests the Sorted/Ordered LASSO ( aka Ordered L1 regularized Least Squares) problem
    Also known as SLOPE for Sorted L-One Penalized Estimation

    min_x sum(lambda*sort(abs(x),'descend')) + .5||A(x)-b||_2^2

    lambda must be a vector in decreasing order, and all strictly positive

    Like the test_LASSO.m file, we will use the notation (A,b,x)
    In the paper mentioned below, this corresponds to the notation (X,y,beta)

 Reference:
   "Statistical Estimation and Testing via the Ordered l1 Norm"
   by M. Bogdan, E. van den Berg, W. Su, and E. J. Candès, 2013
   http://www-stat.stanford.edu/~candes/OrderedL1/

see also test_sBPDN.m and test_LASSO.m

%}

% Before running this, please add the TFOCS base directory to your path
myAwgn = @(x,snr) x + ...
        10^( (10*log10(sum(abs(x(:)).^2)/length(x(:))) - snr)/20 )*randn(size(x));
%%
% Try to load the problem from disk
fileName = fullfile(tfocs_where,...
    'examples','smallscale','reference_solutions','ordered_lasso_problem1_noisy');
randn('state',34324);
rand('state',34324);
N = 1024;
M = round(N/2);
K = round(M/5);
A = randn(M,N);
% give A unit-normed columns
A = bsxfun(@times,A,1./sqrt(sum(A.^2,1)));
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
    sigma = 10^( (10*log10(  norm(b_original)^2/N)  - snr)/20 );
    b   = myAwgn(b_original,snr);
    x_original = x;
    
    lambda = 2*sigma*sqrt(2*log(N)); % for when A has unit-normed columns
    % Now, we diverge from test_LASSO.m, and make lambda a vector
%     lambda = fliplr( linspace(.5*lambda,2*lambda,N) )';
    lambda = .5*lambda + 1.5*lambda*rand(N,1); lambda = sort(lambda,'descend')
    
    x0 = zeros(N,1);

    % We cannot get the solution via CVX easily, so solve using our method
    opts = struct('restart',-Inf,'tol',1e-13,'maxits',1000, 'printEvery',10);
    [ x, out, optsOut ] = solver_SLOPE( A, b, lambda, x0, opts );
    x_ref       = x;
    obj_ref     = norm(A*x-b)^2/2 + sum(lambda(:).*sort(abs(x),'descend'));
    
    save(fileName,'x_ref','b','x_original','lambda',...
        'sigma','b_original','obj_ref','x0','time_IPM','snr');
    fprintf('Saved data to file %s\n', fileName);
    
end

[M,N]           = size(A);
K               = nnz(x_original);
norm_x_ref      = norm(x_ref) + 1*( norm(x_ref)==0 );
norm_x_orig     = norm(x_original) + 1*( norm(x_original)==0 );
er_ref          = @(x) norm(x-x_ref)/norm_x_ref;
er_signal       = @(x) norm(x-x_original)/norm_x_orig;
resid           = @(x) norm(A*x-b)/norm(b);  % change if b is noisy

fprintf('\tA is %d x %d, original signal has %d nonzeros\n', M, N, K );
fprintf('\tl1-norm solution and original signal differ by %.2e (mean(lambda) = %.2e)\n', ...
    norm(x_ref - x_original)/norm(x_original),mean(lambda) );

%% Call the TFOCS solver
er              = er_ref;  % error with reference solution (from IPM)
opts = struct('restart',-Inf,'autoRestart','gradient', ...
    'tol',1e-13,'maxits',1000, 'printEvery',10);
opts.errFcn     = { @(f,primal) er(primal), ...
                    @(f,primal) f - obj_ref   }; 
tic;
[ x, out, optsOut ] = solver_SLOPE( A, b, lambda, x0, opts );
time_TFOCS = toc;

fprintf('Solution has %d nonzeros.  Error vs. reference solution is %.2e\n',...
    nnz(x), er(x) );

% Check that we are within allowable bounds
if out.err(end,1) < 1e-7
    disp('Everything is working');
else
    error('Failed the test');
end

% TFOCS v1.3 by Stephen Becker, Emmanuel Candes, and Michael Grant.
% Copyright 2013 California Institute of Technology and CVX Research.
% See the file LICENSE for full license information.
