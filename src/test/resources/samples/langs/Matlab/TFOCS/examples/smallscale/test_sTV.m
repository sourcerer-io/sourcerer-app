%{
    Tests total-variation problem

    min_x ||x||_TV
s.t.
    || A(x) - b || <= eps

The solvers solve a regularized version

see also test_sBP.m and test_sBPDN_W.m

requires the image processing toolbox for this demo
(but the TFOCS solver does not rely on this toolbox)

See also the TV examples in examples/largescale

%}

% Before running this, please add the TFOCS base directory to your path

myAwgn = @(x,snr) x + ...
        10^( (10*log10(sum(abs(x(:)).^2)/length(x(:))) - snr)/20 )*randn(size(x));

% Try to load the problem from disk
fileName = fullfile('reference_solutions','tv_problem1_smoothed_noisy');
randn('state',245);
rand('state',245);
n = 32;
n1 = n;
n2 = n-1;           % testing the code with non-square signals
N = n1*n2;
M = round(N/2);
A = randn(M,N);
if exist([fileName,'.mat'],'file')
    load(fileName);
    fprintf('Loaded problem from %s\n', fileName );
else
    
    % Generate a new problem

    n = max(n1,n2);
    x = phantom(n); 
    x = x(1:n1,1:n2);
    x_original = x;
    
    mat = @(x) reshape(x,n1,n2);
    vec = @(x) x(:);
  

    b_original = A*vec(x_original);
    snr = 40;  % SNR in dB
    b   = myAwgn(b_original,snr);
    EPS = norm(b-b_original);
    
    tv = linop_TV( [n1,n2], [], 'cvx' );
    
    mu = .005*norm( tv(x_original) ,Inf);
    x0 = zeros(n1,n2);

    % get reference via CVX
    tic
    cvx_begin
        cvx_precision best
        variable xcvx(n1,n2)
        minimize tv(xcvx) + mu/2*sum_square(vec(xcvx)-vec(x0) )
        subject to
            norm(A*vec(xcvx) - b ) <= EPS
    cvx_end
    time_IPM = toc;
    x_ref = xcvx;
    obj_ref = tv(x_ref) + mu/2*sum_square(vec(x_ref)-vec(x0) );
    
    save(fileName,'x_ref','b','x_original','mu',...
        'EPS','b_original','obj_ref','x0','time_IPM','snr');
    fprintf('Saved data to file %s\n', fileName);
    
end

imshow( [x_original, x_ref] );

[M,N]           = size(A);
[n1,n2]         = size(x_original);
norm_x_ref      = norm(x_ref,'fro');
norm_x_orig     = norm(x_original,'fro');
er_ref          = @(x) norm(vec(x)-vec(x_ref))/norm_x_ref;
er_signal       = @(x) norm(x-x_original)/norm_x_orig;
resid           = @(x) norm(A*vec(x)-b)/norm(b);  % change if b is noisy


%% Call the TFOCS solver
er              = er_ref;  % error with reference solution (from IPM)
opts = [];
opts.restart    = 1000;
opts.errFcn     = { @(f,dual,primal) er(primal), ...
                    @(f,dual,primal) obj_ref - f  }; 
opts.maxIts     = 1000;

W   = linop_TV( [n1,n2] );
normW           = linop_TV( [n1,n2], [], 'norm' );
opts.normW2     = normW^2;
z0  = [];   % we don't have a good guess for the dual
tic;
[ x, out, optsOut ] = solver_sBPDN_W( A, W, b, EPS, mu, vec(x0), z0, opts );
time_TFOCS = toc;

fprintf('Solution has %d nonzeros.  Error vs. IPM solution is %.2e\n',...
    nnz(x), er(x) );

% Check that we are within allowable bounds
if out.err(end,1) < 1e-4
    disp('Everything is working');
else
    error('Failed the test');
end

% TFOCS v1.3 by Stephen Becker, Emmanuel Candes, and Michael Grant.
% Copyright 2013 California Institute of Technology and CVX Research.
% See the file LICENSE for full license information.
