%{
    Tests total-variation problem and l1 analysis
        on a large-scale example

    min_x   alpha*||x||_TV + beta*||Wx||_1
s.t.
    || A(x) - b || <= eps

where W is a wavelet operator.


This requires:

    (1) SPOT            www.cs.ubc.ca/labs/scl/spot/
    (2) Wavelab         www-stat.stanford.edu/~wavelab/ 
and optionally,
    (3) CurveLab        www.curvelet.org/

    Also demonstrates how to use SPOT with TFOCS.
    To install SPOT, please visit:
    http://www.cs.ubc.ca/labs/scl/spot/

    We use SPOT to call WaveLab and CurveLab,
    which may need to be installed separately.
    Please contact the TFOCS and/or SPOT authors if you need help.

    Also, SPOT v1.0 has a typo in its curvelet code:
        after adding SPOT to your path, edit this file
            edit spotbox-1.0p/opCurvelet
        and change all instances of "fdct_c2v" and "fdct_v2c"
        to "spot.utils.fdct_c2v" and "spot.utils.fdct_v2c", resp.

%}

% Setting up the various packages (change this for your computer):
addpath ~/Dropbox/TFOCS/
addpath ~/Documents/MATLAB/spotbox-1.0p/
addpath ~/Documents/MATLAB/CurveLab-2.1.2/fdct_wrapping_cpp/mex/

myAwgn = @(x,snr) x +10^( (10*log10(sum(abs(x(:)).^2)/length(x(:))) - snr)/20 )*...
    randn(size(x));
%% Load an image and take noisy measurements


n1 = 256;
n2 = 256;
N = n1*n2;
x = phantom(n1);

% Signal-to-noise ratio, in dB
snr = 5;


x_original = x;
mat = @(x) reshape(x,n1,n2);
% vec = @(x) x(:);

% Add noise:
randn('state',245); rand('state',245);
x_noisy = myAwgn( x_original, snr);

maxI    = max(vec(x_original)); % max pixel value
PSNR    = @(x) 20*log10(maxI*sqrt(N)/norm(vec(x)-vec(x_original) ) );

% Take measurements
b   = vec(x_noisy);
b_original = vec(x_original);
EPS = .8*norm(b-b_original);

figure(2); imshow( [x_original, x_noisy] ); drawnow;
M=N;
fprintf('Denoising problem, %d x %d, signal has SNR %d dB\n',M, N, round(snr) );

REWEIGHT    = false; % whether to do one iteration of reweighting or not
%% Call the TFOCS solver

mu              = 5;
er              = @(x) norm(x(:)-x_original(:))/norm(x_original(:));
opts = [];
opts.errFcn     = @(f,dual,primal) er(primal);
opts.maxIts     = 100;
opts.printEvery = 20;
opts.tol        = 1e-4;
opts.stopcrit   = 4;

x0 = x_noisy;
z0  = [];   % we don't have a good guess for the dual

% build operators:
A           = linop_handles([N,N], @(x)x, @(x) x );
normA2      = 1;
W_wavelet   = linop_spot( opWavelet(n1,n2,'Daubechies') );
if exist('fdct_wrapping')
    DO_CURVELETS = true;
    W_curvelet  = linop_spot( opCurvelet(n1,n2) );
else
    % You either don't have curvelab installed
    % or you need to add it to the matlab path.
    DO_CURVELETS = false;
end
W_tv        = linop_TV( [n1,n2] );
normWavelet      = linop_normest( W_wavelet );
if DO_CURVELETS, normCurvelet     = linop_normest( W_curvelet ); end
normTV           = linop_TV( [n1,n2], [], 'norm' );

contOpts            = [];
contOpts.maxIts     = 4;

%% -- First, solve just via wavelet --
clc; disp('WAVELETS');
[x_wavelets,out_wave] = solver_sBPDN_W( A, W_wavelet, b, EPS, mu, ...
    x0(:), z0, opts, contOpts);

if REWEIGHT
    % do some re-weighting:
    coeff   = W_wavelet( x_wavelets, 1 );
    weights = findWeights( coeff, .85 );
    W_weights = linop_handles( [length(weights),length(weights)], @(x)weights.*x,...
        @(y) weights.*y, 'R2R' );
    [x_wavelets,out_wave] = solver_sBPDN_W( A, ...
        linop_compose(W_weights,W_wavelet),  ...
        b, EPS, mu, x_wavelets, out_wave.dual, opts, contOpts);
    % and of course, you could keep iterating...
end
%% -- Second, solve just via curvelets --
if DO_CURVELETS
    opts_copy = opts;
    opts_copy.maxIts    = 10;
    opts_copy.normA2    = 1;
    opts_copy.normW2    = normCurvelet^2;
    clc; disp('CURVELETS');
    [x_curvelets,out_curve] = solver_sBPDN_W( A, W_curvelet, b, EPS, mu, x0(:), z0, opts_copy);
    
    if REWEIGHT
        % do some re-weighting:
        coeff   = W_curvelet( x_curvelets, 1 );
        weights = findWeights( coeff, .85 );
        W_weights = linop_handles( [length(weights),length(weights)], @(x)weights.*x,...
            @(y) weights.*y, 'R2R' );
        % really, we should update the norm of W, since it is changing slightly
        %   by adding in the weights, but that is a slow calculation, and the norm
        %   doesn't change too much, so we skip that.
        [x_curvelets,out_curve] = solver_sBPDN_W( A, ...
            linop_compose(W_weights,W_curvelet),  ...
            b, EPS, mu, x_curvelets, out_curve.dual, opts_copy);
    end
end

%% -- Third, solve just via TV --
clc; disp('TV');
opts_copy = opts;
opts_copy.normA2     = 1;
opts_copy.normW2     = normTV^2;
opts_copy.continuation  = false;
[x_tv,out_tv] = solver_sBPDN_W( A, W_tv, b, EPS, mu, x0(:), z0, opts_copy, contOpts);

if REWEIGHT
    % do some re-weighting:
    coeff   = W_tv( x_tv, 1 );
    weights = findWeights( coeff, .95 );
    W_weights = linop_handles( [length(weights),length(weights)], @(x)weights.*x,...
        @(y) weights.*y, 'C2C' );
    % really, we should update the norm of W, since it is changing slightly
    %   by adding in the weights, but that is a slow calculation, and the norm
    %   doesn't change too much, so we skip that.
    [x_tv,out_tv] = solver_sBPDN_W( A, ...
        linop_compose(W_weights,W_tv),  ...
        b, EPS, mu, x_tv, out_tv.dual, opts_copy);
end
%% -- Fourth, combine wavelets (or curvelets) and tv --
alpha   = 1;    % weight of TV term
beta    = .05;   % weight of wavelet term
normW12     = normTV^2;
if DO_CURVELETS, normW22 = normCurvelet^2; beta = .5;
else, normW22     = normWavelet^2; end

% x =solver_sBPDN_WW( A, alpha, W_tv, beta, ...
%       W_wavelet, b, EPS, mu,vec(x0), z0, opts, contOpts);

%  this is what solver_sBPDN_WW is doing:
W1  = W_tv;
if DO_CURVELETS
    W2  = W_curvelet;
else
    W2  = W_wavelet;
end
prox       = { prox_l2( EPS ), ...
               proj_linf( alpha ),...
               proj_linf( beta ) };
affine     = { A, -b; W1, 0; W2, 0 };

% x = tfocs_SCD( [], affine, prox, mu, x0(:), z0, opts, contOpts );
% X_wavelets_tv = mat(x);
%% try with box constraints
% Constrain the image pixels to be in the range 0 <= x <= 1
prox       = { prox_l2( EPS ), ...
               proj_linf( alpha ),...
               proj_linf( beta ), ...
               proj_Rplus , ...
               proj_Rplus};

affine     = { A, -b; W1, 0; W2, 0 ; 1, 0; -speye(n1*n2), maxI*ones(n1*n2,1) };

x_wavelets_tv = tfocs_SCD( [], affine, prox, mu, x0(:), z0, opts, contOpts );
fprintf('Min and max entry of recovered image are %.1f and %.1f\n', min(min(x_wavelets_tv)),...
    max(max(x_wavelets_tv)) );
%% another way to use box constraints
% Instead of thinking of it as two scaled X >= 0 constraints,
%   we call the special purpose atom

prox       = { prox_l2( EPS ), ...
               proj_linf( alpha ),...
               proj_linf( beta ), ...
               prox_boxDual(0,maxI,-1) };
           
affine     = { A, -b; W1, 0; W2, 0 ; 1, 0 };
opts_copy = opts;
opts_copy.continuation  = false;
opts_copy.maxIts        = 30;
[x_wavelets_tv,out] = tfocs_SCD( [], affine, prox, mu, x0(:), z0, opts_copy, contOpts );

if REWEIGHT
    % do some re-weighting:
    weights = findWeights( W1(x_wavelets_tv,1), .95 );
    W_weights1 = linop_handles( [length(weights),length(weights)], @(x)weights.*x,...
        @(y) weights.*y, 'C2C' );
    weights = findWeights( W2(x_wavelets_tv,1), .95 );
    W_weights2 = linop_handles( [length(weights),length(weights)], @(x)weights.*x,...
        @(y) weights.*y, 'C2C' );

    affine     = { A, -b; linop_compose(W_weights1,W1), 0; ...
        linop_compose(W_weights2,W2) , 0 ; -1, 0 }; % Note: we need the "-1", not +1
    [x_wavelets_tv,out] = tfocs_SCD( [], affine, prox, mu, x0(:), out.dual, opts_copy, contOpts );

end
fprintf('Min and max entry of recovered image are %.1f and %.1f\n', min(min(x_wavelets_tv)),...
    max(max(x_wavelets_tv)) );
%% Plot everything
figure(1); clf;
splot = @(n) subplot(2,3,n);

splot(1);
imshow(x_original);
title(sprintf('Noiseless image,\nPSNR %.1f dB', Inf ));

splot(2);
imshow(x_noisy);
title(sprintf('Noisy image,\nPSNR %.1f dB', PSNR(x_noisy) ));

if DO_CURVELETS
    splot(3);
    imshow(mat(x_curvelets));
    title(sprintf('Curvelet regularization,\nPSNR %.1f dB', PSNR(x_curvelets) ));
end

splot(4);
imshow(mat(x_wavelets));
title(sprintf('Wavelet regularization,\nPSNR %.1f dB', PSNR(x_wavelets) ));

splot(5);
imshow(mat(x_tv));
title(sprintf('TV regularization,\nPSNR %.1f dB', PSNR(x_tv) ));

splot(6);
imshow(mat(x_wavelets_tv));
if DO_CURVELETS
    title(sprintf('Curvelets + TV, and box constraints,\nPSNR %.1f dB', PSNR(x_wavelets_tv) ));
else
    title(sprintf('Wavelets + TV, and box constraints,\nPSNR %.1f dB', PSNR(x_wavelets_tv) ));
end

%% Bonus: movie.
% This uses the helper file "plotNow.m" to show you the image
% at every iteration. It slows down the algorithm on purpose
% so that you have time to watch it.
figure(2); clf; plotNow();
time_delay = 0.1;
opts.errFcn = {@(f,d,p) er(p), @(f,d,p) plotNow( mat(p), time_delay) };
x_tv = solver_sBPDN_W( A, W_tv, b, EPS, .1*mu, vec(x0), z0, opts);
title('THAT''S ALL FOLKS');
%%
% TFOCS v1.3 by Stephen Becker, Emmanuel Candes, and Michael Grant.
% Copyright 2013 California Institute of Technology and CVX Research.
% See the file LICENSE for full license information.
