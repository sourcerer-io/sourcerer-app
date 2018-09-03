%{
    Tests the "analysis" form of basis pursuit de-noising

    min_x ||Wx||_1
s.t.
    || A(x) - b || <= eps

This version uses a realistic problem

see also test_sBP.m and test_sBPDN.m and test_sBPDN_W.m

This example requires PsiTransposeWFF.m and PsiWFF.m (should be included in this directory)

%}

% Before running this, please add the TFOCS base directory to your path


HANDEL = load('handel');        % This comes with Matlab
x_original = HANDEL.y;          % It's a clip from Handel's "Hallelujah"
FS = HANDEL.Fs;                 % The sampling frequency in Hz

PLAY = input('Play the original music clip? (y/n) ','s');
if strcmpi(PLAY,'y') || strcmpi(PLAY,'yes')
    sound( x_original );
end
N = length(x_original);
% Simplest to use signals of size 2^k for any integer k > 0
% So, padd the signal with zeros at the end
k = nextpow2(N);
k = k-1;
x_original = [x_original(1:min(N,2^k)); zeros(2^k-N,1) ];
N_short = N;
N = 2^k;

% We'll perform denoising.  Measurement is the identity.
M = N;
Af = @(x) x;
At = Af;
normA   = 1;
A = linop_handles( [M,N], Af, At );
% linop_test(A)

myAwgn = @(x,snr) x + ...
        10^( (10*log10(sum(abs(x(:)).^2)/length(x(:))) - snr)/20 )*randn(size(x));

snr     = 10;   % in dB
b_exact = Af(x_original);
x_noisy = myAwgn(x_original,snr);
b       = Af(x_noisy);

PLAY = input('Play the noisy music clip? (y/n) ','s');
if strcmpi(PLAY,'y') || strcmpi(PLAY,'yes')
    sound( x_noisy );
end

EPS = norm( b - b_exact );
fprintf('||b-Ax||/||b|| is %.2f\n', EPS/norm(b) );

%% SETUP AN ANALYSIS OPERATOR
% The PsiWFF and PsiTransposeWFF code is a Gabor frame
% (i.e. a short-time Fourier transform)
% written by Peter Stobbe
% 
% PsiWFF is the synthesis operator, and acts on coefficients
% PsiTransposeWFF is the analysis operator, and acts on signals
gMax        = 0;
% gMax        = -8; % 2.6e-1 er with -8
gLevels     = 1 - gMax;
tRedundancy = 1;
fRedundancy = 0;

gWindow = 'isine';
logN    = log2(N);
psi     = @(y) PsiWFF(y,gWindow,logN,logN-gLevels,logN+gMax,tRedundancy,fRedundancy);
psiT    = @(x) PsiTransposeWFF(x,gWindow,logN,logN-gLevels,logN+gMax,tRedundancy,fRedundancy);

x  = x_original;
y  = psiT(x);
x2 = psi(y);
d  = length(y);
% The frame is tight, so the psuedo-inverse is just the transpose:
fprintf('Error in PSI(PSI^* x ) - x is %e; N = %d, d = %d, d/N = %.1f\n', ...
    norm(x-x2),N,d,d/N);

normW   = 1;
W       = linop_handles([d,N], psiT, psi );
linop_test(W)
%% Call the TFOCS solver

x0  = x_noisy;
mu  = .5*norm(psiT(x0),Inf);
norm_x_orig     = norm(x_original);
er_signal       = @(x) norm(x-x_original)/norm_x_orig;

opts            = [];
opts.errFcn     = @(f,dual,primal) er_signal(primal);
opts.maxIts     = 80;
opts.tol        = 1e-6;
opts.normA2     = normA^2;
opts.normW2     = normW^2;  % both of these are 1
opts.printEvery = 20;
z0  = [];   % we don't have a good guess for the dual
tic;

W_weighted  = W;
% do some reweighting
for rw = 1:2
    
    % This is the old method of doing continuation.  The current version
    %   supports a simpler way to make the solver use continuation;
    %   for an example, see "example_LinearProgram.m" in the examples/smallscale directory.
    solver = @(mu,x0,z0,opts) solver_sBPDN_W( A, W_weighted, b, EPS, mu, x0, z0, opts );
    contOpts        = [];
    contOpts.maxIts = 1;
    [ x, out, optsOut ] = continuation( solver, mu, x0, z0, opts,contOpts );
    
    % update weights
    coeff   = psiT(x);
    cSort   = sort(abs(coeff),'descend');
    cutoff  = cSort( find( cumsum(cSort.^2)/sum(cSort.^2) >= .9, 1 ) );
    weights = 1./( abs(coeff) + cutoff );
    weightsMatrix   = spdiags(weights,0,d,d);
    W_weighted      = linop_compose( weightsMatrix , W );
    opts.normW2     = []; % let the solver estimate it for us
    
    x0  = x;
    z0  = cell( out.dual );
end


time_TFOCS = toc;

fprintf('Denoised signal has error %.2e, noisy signal has error %.2e\n',...
    er_signal(x), er_signal(x_noisy) );
%%
PLAY = input('Play the recovered signal music clip? (y/n) ','s');
if strcmpi(PLAY,'y') || strcmpi(PLAY,'yes')
    sound( x );
end
PLAY = input('Play the noisy music clip? (y/n) ','s');
if strcmpi(PLAY,'y') || strcmpi(PLAY,'yes')
    sound( x_noisy );
end


% TFOCS v1.3 by Stephen Becker, Emmanuel Candes, and Michael Grant.
% Copyright 2013 California Institute of Technology and CVX Research.
% See the file LICENSE for full license information.
