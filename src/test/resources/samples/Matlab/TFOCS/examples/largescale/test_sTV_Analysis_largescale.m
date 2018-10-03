%{
    Tests total-variation problem and l1 analysis
        on a large-scale example

    min_x alpha*||x||_TV + beta*||Wx||_1
s.t.
    || A(x) - b || <= eps

where W is a wavelet operator.
The solvers solve a regularized version

see also test_sBP.m and test_sBPDN_W.m and test_sTV.m and test_sTV_largescale.m

This version has no reference solution.

This code uses continuation

Requires wavelet toolbox and image processing toolbox

%}

% Before running this, please add the TFOCS base directory to your path


% Generate a new problem

randn('state',245);
rand('state',245);

% image = 'phantom';
image = 'bugsbunny';

switch image
    case 'phantom'
        n = 256;
        n1 = n;
        n2 = n;
        % n2 = n-1;           % testing the code with non-square signals
        N = n1*n2;
        n = max(n1,n2);
        x = phantom(n);
        x = x(1:n1,1:n2);
        
%         snr = -5;  % SNR in dB
        snr = 5;
    case 'bugsbunny'
        % Image is from wikimedia commons:
        % http://commons.wikimedia.org/wiki/File:Falling_hare_bugs.jpg
        load BugsBunny
        x = bugs;
        [n1,n2] = size(x);
        N = n1*n2;
        
        snr = 15;  % SNR in dB
end
x_original = x;

mat = @(x) reshape(x,n1,n2);
vec = @(x) x(:);

% -- Choose what kind of measurements you want:
measurements = 'identity';          % for denoising

switch measurements
    case 'identity'
        M = N;
        Af = @(x) x;
        At = @(x) x;
end

% treat X as n1*n2 x 1 vector?
VECTOR = true;
% or treat X as n1 x n2 matrix?
% VECTOR = false;

if VECTOR
    A = linop_handles([M,N], Af, At );
    VEC = vec;
else
    Af = @(x) vec(Af(x));
    At = @(x) mat(At(x));
    A = linop_handles({[n1,n2],[M,1]}, Af, At );
    VEC = @(x) x;
end
    
    
b_original = Af(vec(x_original));

myAwgn = @(x,snr) x + ...
        10^( (10*log10(sum(abs(x(:)).^2)/length(x(:))) - snr)/20 )*randn(size(x));

% Either add white noise:
x_noisy = myAwgn( x_original, snr );
% Or add a random mask:
% x_temp  = myAwgn( x_original, 0);
% index   = randperm(N);
% index   = index( 1 : round(.2*N) );
% x_noisy = x_original;
% x_noisy(index) = x_temp(index);

b   = Af( vec(x_noisy) );
EPS = .9*norm(b-b_original);
figure(2); imshow( [x_original, x_noisy] );

%% Setup a sparsifying dictionary to use for denoising:
% Choose an extension mode; see "dwtmode".  This makes things square
dwtmode('per');
X       = x_original;
Xbp     = x_noisy;
maxI    = 1; % max pixel value
PSNR    = @(x) 20*log10(maxI*sqrt(N)/norm(vec(x)-vec(x_original) ) );

% symmetric 9/7 biothogonal wavelets are what JPEG-2000 uses
waveletType = 'bior4.4'; % 9/7 wavelet
nLevels = min( 1, wmaxlev(size(Xbp),waveletType) );
[c,s] = wavedec2(Xbp,nLevels,waveletType);  % see 'wfilters' for options. Needs wavelet toolbox
PLOT = true;
if PLOT
    D = detcoef2( 'h', c, s, 1 );
    D = [D,detcoef2( 'd', c, s, 1 )];
    a = appcoef2( c, s, 'db3', 1);
    D = [D;detcoef2( 'v', c, s, 1 ), a];
    cSort = sort(abs(c),'descend');
    
    % Try wavelet hard thresholding to denoise
    erBest = -Inf;
    for gamma = .81:.01:.999
        ind = [find( cumsum(cSort.^2)/sum(cSort.^2) > gamma ),N];
        cutoff = cSort(ind(1));
        c2 = c;
        c2 = c.*( abs(c)>cutoff);
        X_hat = waverec2(c2,s,waveletType);
        er = PSNR(X_hat);
%         fprintf('Gamma is %.3f, PSNR is %.2f\n',gamma,er );
        if er > erBest, erBest = er;  gammaBest = gamma; end
    end
%     gammaBest = .9;
    ind = [find( cumsum(cSort.^2)/sum(cSort.^2) > gammaBest ),N];
    cutoff = cSort(ind(1));
    c2 = c.*( abs(c)>cutoff);
    X_hat = waverec2(c2,s,waveletType);
    
    figure(2);
    imshow( [X,Xbp,X_hat] );
    title(sprintf('Original\t\tNoisy (PSNR %.1f dB)\tOracle Wavelet Thresholding (PNSR %.1f dB)',...
        PSNR(Xbp), PSNR(X_hat) ) );
end

% Forward wavelet operator
Wf = @(X) wavedec2(mat(X),nLevels,'bior4.4')';
W_invF = @(c) vec(waverec2(vec(c),s,'bior4.4') );
pinvW = W_invF;

Wt    = @(c) vec(waverec2(vec(c),s,'rbio4.4') );
pinvWt = @(X) wavedec2(mat(X),nLevels,'rbio4.4')';
d = length(c);
if d ~= N, disp('warning: wavelet transform not square'); end

W_wavelet       = linop_handles([N,N], Wf, Wt );
normWavelet     = linop_test(W_wavelet);
%%
mu  = 1e-3*norm( linop_TV(x_original) ,Inf);
x_ref   = x_original;

% imshow( [x_original, x_noisy] );

sz              = A([],0);
M               = sz{2}(1);
N               = sz{1}(1);
[n1,n2]         = size(x_original);
norm_x_ref      = norm(x_ref,'fro');
er_ref          = @(x) norm(vec(x)-vec(x_ref))/norm_x_ref;

fprintf('\tA is %s, %d x %d, signal has SNR %d dB\n', measurements, M, N, round(snr) );

%% Call the TFOCS solver
er              = er_ref;  
opts = [];
opts.restart    = 1000;
opts.errFcn     = @(f,dual,primal) er(primal);
opts.maxIts     = 100;
opts.printEvery = 20;
opts.tol        = 1e-4;
if strcmpi(measurements,'identity')
    x0 = x_noisy;
else
    x0 = At(b);
end
z0  = [];   % we don't have a good guess for the dual
if VECTOR
    W_tv   = linop_TV( [n1,n2] );
else
    W_tv   = linop_TV( {n1,n2} );
%     z0  = {zeros(M,1), zeros(n1*n2,1) };
end
normTV           = linop_TV( [n1,n2], [], 'norm' );
opts.normW12     = normTV^2;
opts.normW22     = normWavelet^2;
opts.normA2      = 1; % "A" is the identity


% Make sure we didn't do anything bad
% linop_test( A );
% linop_test( W );

contOpts            = [];
contOpts.maxIts     = 4;
contOpts.betaTol    = 2;


% -- First, solve just via wavelet --
disp('============ WAVELETS ONLY ===============');
opts.normW2     = normWavelet^2;
solver = @(mu,x0,z0,opts) solver_sBPDN_W( A, W_wavelet, b, EPS, mu, x0, z0, opts);
[ x, out, optsOut ] = continuation(solver,5*mu,VEC(x0),z0,opts, contOpts);
X_wavelets = mat(x);

% -- Second, solve just via TV --
disp('============ TV ONLY =====================');
opts.normW2     = normTV^2;
solver = @(mu,x0,z0,opts) solver_sBPDN_W( A, W_tv, b, EPS, mu, x0, z0, opts);
[ x, out, optsOut ] = continuation(solver,5*mu,VEC(x0),z0,opts, contOpts);
X_tv = mat(x);

% -- Third, combine wavelets and tv --
% -- Here is what we are solving --
% minimize   alpha*||x||_TV + beta*||W_wavelet(x)||_1
% subject to    ||x-x_noisy|| <= EPS
alpha   = 1;
beta    = .1;

disp('============ WAVELETS AND TV =============');
solver = @(mu,x0,z0,opts) solver_sBPDN_WW( A, alpha, W_tv, beta, W_wavelet, b, EPS, mu,x0, z0, opts);
[ x, out, optsOut ] = continuation(solver,5*mu,VEC(x0),z0, opts,contOpts);
X_wavelets_tv = mat(x);

%%
figure(1); clf;
splot = @(n) subplot(2,3,n);

splot(1);
imshow(x_original);
title(sprintf('Noiseless image, PSNR %.1f dB', Inf ));

splot(2);
imshow(x_noisy);
title(sprintf('Noisy image, PSNR %.1f dB', PSNR(x_noisy) ));

splot(3);
imshow(X_hat);
title(sprintf('Oracle wavelet thresholding, PSNR %.1f dB', PSNR(X_hat) ));

splot(4);
imshow(X_wavelets);
title(sprintf('Wavelet regularization, PSNR %.1f dB', PSNR(X_wavelets) ));

splot(5);
imshow(X_tv);
title(sprintf('TV regularization, PSNR %.1f dB', PSNR(X_tv) ));

splot(6);
imshow(X_wavelets_tv);
title(sprintf('Wavelet + TV regularization, PSNR %.1f dB', PSNR(X_wavelets_tv) ));

%%
% TFOCS v1.3 by Stephen Becker, Emmanuel Candes, and Michael Grant.
% Copyright 2013 California Institute of Technology and CVX Research.
% See the file LICENSE for full license information.
