%{
    Tests total-variation problem on a large-scale example

    min_x ||x||_TV
s.t.
    || A(x) - b || <= eps

The solvers solve a regularized version

see also test_sBP.m and test_sBPDN_W.m and test_sTV.m

This version has no reference solution.
Requires image processing toolbox

%}

% Before running this, please add the TFOCS base directory to your path


% Generate a new problem

randn('state',245);
rand('state',245);

n = 256;
n1 = n; 
n2 = n;
% n2 = n-1;           % testing the code with non-square signals
N = n1*n2;
n = max(n1,n2);
x = phantom(n);
x = x(1:n1,1:n2);
x_original = x;

mat = @(x) reshape(x,n1,n2);
vec = @(x) x(:);

% -- Choose what kind of measurements you want:
measurements = 'identity';          % for denoising
% measurements = 'partialFourier';    % partial 2D DCT

switch measurements
    case 'identity'
        M = N;
        Af = @(x) x;
        At = @(x) x;
    case 'partialFourier'

        M = round( N / 4 );
        % omega = randsample(N,M);
        omega = randn(N,1);
        [temp,omega] = sort(omega);
        omega = sort( omega(1:M) );
        downsample = @(x) x(omega);
        SS.type = '()'; SS.subs{1} = omega; SS.subs{2} = ':';
        upsample = @(x) subsasgn( zeros(N,size(x,2)),SS,x);


        % take partial 2D DCT measurements.  We have Af(At) = identity (not
        % vice-versa of course). Randomly permuted.
        rp = randperm(N);
        [~,rp_inv] = sort(rp);
        rpF = @(x) x(rp);
        rp_invF = @(x) x(rp_inv);
        
        my_dct2 = @(x) dct(dct(x).').';
        my_idct2= @(x) idct(idct(x).').';
        Af = @(x) downsample(vec( my_dct2( mat(rpF(mat(x) )) ) ) );
        At = @(y) vec( rp_invF( my_idct2( mat( upsample( y ) ) ) ) );
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
    
myAwgn = @(x,snr) x + ...
        10^( (10*log10(sum(abs(x(:)).^2)/length(x(:))) - snr)/20 )*randn(size(x));
    
b_original = Af(vec(x_original));
snr = 10;  % SNR in dB
x_noisy = myAwgn( x_original, snr );
b   = Af( vec(x_noisy) );
EPS = norm(b-b_original);

mu  = 1e-5*norm( linop_TV(x_original) ,Inf);
x_ref   = x_original;

imshow( [x_original, x_noisy] );

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
opts.maxIts     = 250;
if strcmpi(measurements,'identity')
    x0 = x_ref;
else
    x0 = At(b);
end
z0  = [];   % we don't have a good guess for the dual
if VECTOR
    W   = linop_TV( [n1,n2] );
else
    W   = linop_TV( {n1,n2} );
end
normW           = linop_TV( [n1,n2], [], 'norm' );
opts.normW2     = normW^2;

% Make sure we didn't do anything bad
% linop_test( A );
% linop_test( W );


tic;
% [ x, out, optsOut ] = solver_sBPDN_W( A, W, b, EPS, mu, VEC(x0), z0, opts
% );
solver = @(mu,x0,z0,opts) solver_sBPDN_W( A, W, b, EPS, mu, x0, z0, opts);
[ x, out, optsOut ] = continuation(solver,5*mu,x0(:),z0,opts);

time_TFOCS = toc;
fprintf('Solution has %d nonzeros.  Error vs. original solution is %.2e\n',...
    nnz(x), er(x) );

x = mat(x);
imshow( [x_original, x_noisy, x] );
maxI    = 1; % max pixel value
PSNR    = @(x) 20*log10(maxI*sqrt(N)/norm(vec(x)-vec(x_original) ) );
title(sprintf('No denoising, PSNR is %.1f dB; TV denoising, PSNR is %.1f dB',...
    PSNR( x_noisy ), PSNR( x )) );
%%
% TFOCS v1.3 by Stephen Becker, Emmanuel Candes, and Michael Grant.
% Copyright 2013 California Institute of Technology and CVX Research.
% See the file LICENSE for full license information.
