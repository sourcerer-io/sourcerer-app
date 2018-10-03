%{
    5/28/09, 10/28/10
    pauli-matrix tensor measurements
    Stephen Becker, srbecker@caltech.edu

    See http://arxiv.org/abs/0909.3304

We seek to find a low-rank matrix X, because X represents the quantum state
of d atoms (X has dimensions n x n where n = 2^d, due to quantum entanglement).
X is Hermitian and positive semi-definite, and furthermore trace(X) = 1.

From experiments, we have measurements b_i = < A_i, X > where <,> is the 
trace inner product.    A_i is a Hermitian matrix, and is a tensor product
of Pauli matrices.  The observations are noisy.

To recover X, we can consider solving several related variants:

notation:
x = vec(X), X = mat(x)


        minimize     1/2||A*x - b ||^2
        subject to
                    mat(x) >= 0
                    trace(mat(x)) <= 1

(this variant does not require smoothing)

or

        minimize    trace(mat(x))
        subject to
                    mat(x) >= 0
                    ||A*x - b || <= eps
(this variant requires smoothing and/or continuation )

%}
%% Setup a matrix
randn('state',2009);
rand('state',2009);

% -- Generate the state matrix "M" (aka rho)
n1 = 128;  % fast
% n1 = 256;
% n1 = 512;  % works, but slow
n2 = n1; r = 2;
M = ( randn(n1,r) + 1i*randn(n1,r) )*...
    ( randn(r,n2) + 1i*randn(r,n2) )/2;
M=M*M';             % M is Pos. Semidefinite
M = M / trace(M);   % and has trace 1

df = r*(n1+n2-r);   % The degrees of freedom
oversampling = 5;   % Information-theoretic limit corresponds
                    % to oversampling = 1
m = min(5*df,round(.99*n1*n2) ); 

fprintf('%d x %d matrix, %d measurements (%.1f%%, or %.1f oversampling)\n',...
    n1,n2,m,100*m/(n1*n2),m/df );
fprintf('True rank is %d\n', r);
if ~isreal(M), fprintf('Matrix is complex\n'); end

vec = @(x) x(:);
mat = @(x) reshape(x,n1,n2);

%% make some pauli matrices, to use for observations
%{
Using the convention:
 PX = [0,1;1,0]; PY = [0,-1i;1i,0]; PZ =[1,0;0,-1]; PI = eye(2);
 X will be labelled "1", Y labeled "2", Z "3" and I "4"
%}
myRandint = @(M,N,d) ceil(d*rand(M,N));

PAULI_T = sparse([],[],[],n1*n2,m,m*n1 );
fprintf('Taking measurements...      ');
for i=1:m
    fprintf('\b\b\b\b\b\b%5.1f%%', 100*i/m );
    % pick from the X, Y, Z and I uniformly at random
    list = myRandint( log2(n1),1,4 );
    E_i = explicitPauliTensor( list );
    % NOTE: with this definition, E_i is Hermitian,
    % but not positive semidefinite, and not scaled properly.
    
    PAULI_T(:,i) = E_i(:);  % access via column is MUCH faster
end
fprintf('\n');
PAULI = PAULI_T.';      % transpose it, since we were implicitly
clear PAULI_T           % dealing with transpose earlier
                        % (since updating the columns of a sparse
                        % matrix is much more efficient than updating
                        % the rows )   
                        
fprintf('Computing the scaling factor...');
% scale = 1/normest(PAULI*PAULI',1e-2);
% scale = 1/my_normest( @(x) PAULI*(PAULI'*x), size(PAULI,1)*[1,1] );
fprintf(' done.\n');

data = PAULI*vec(M);
% even if measurements are complex, data should still be real
fprintf('due to roundoff, measurements have %.2e imaginary part\n',...
    norm(imag(data))/norm(data) );
data = real(data);

%% Add some noise
%{
    Physics of noise:
        in addition to noise from measurement error, we have a dominant
        source of 'noise' which is because the outcome of our
        measurements is really the result of measuring a quantum wave
        function.  Experimentalists will repeat the same
        measurement many times, so they can estimate the true state,
        but there is inherent quantum mechanical uncertainty to this.
        Basically, we have a state that is determined by a Bernoulli
        parameter 0 < p < 1, but the measurement returns either 0 or 1,
        so we have to take a lot of measurements to estimate p.

        There's also depolarizing noise, which we don't discuss here.

    For simplicity in this example, we don't worry about that model,
    and just add in some pseudo-random white noise
%}

myAwgn = @(x,snr) x + ...
    10^( (10*log10(sum(abs(x(:)).^2)/length(x(:))) - snr)/20 )*randn(size(x));
snr = 40;
b = myAwgn( data, snr );
rms = @(x) norm(x)/sqrt(length(x));
snrF = @(sig,noise) 20*log10( rms(sig)/rms(noise) );
sigma = std( b - data );
fprintf('SNR of measurements is %.1f dB, and std of noise is %.2f\n',...
    snrF(data,data-b), sigma );
%% Solve in TFOCS
%{

Formulation:
        minimize     1/2||PAULI*x - b ||^2
        subject to
                    mat(x) >= 0
                    trace(mat(x)) <= 1

No smoothing is required, but... it's hard to exploit the low-rank
structure of the problem

We do not expect the "error" to go to zero, since the data are noisy
and we don't have the true answer, so we're not really looking
at "error" of the software, but rather modelling error...

%}
opts    = [];
opts.maxIts     = 300;
opts.printEvery = 25;
if n1 > 256
    opts.maxIts     = 50;
    opts.printEvery = 5;
end
opts.errFcn = {@(f,x) norm( vec(x) - vec(M) )/norm(M,'fro')};
% this may be slow:
% opts.errFcn{2} = @(f,x) rank(mat(x));

tau     = 1; % constraint on trace
x0      = [];

A   = linop_matrix( PAULI, 'C2R' );
[x,out,optsOut] = tfocs(smooth_quad,{A,-b}, proj_psdUTrace(tau) , x0, opts );
X = mat(x);

figure(1);
semilogy( out.err(:,1) );
hold all
%% Solve in TFOCS
%{

Formulation:
        minimize    trace(mat(x))   + mu/2*||x-x0||^2
        subject to
                    mat(x) >= 0
                    ||PAULI*x - b || <= eps

We solve this via a dual method, hence the mu term.
We can reduce its effect by using continuation (i.e. updating x0)

%}
opts    = [];
opts.maxIts     = 50;
opts.printEvery = 25;
opts.errFcn = {@(f,dual,x) norm( vec(x) - vec(M) )/norm(M,'fro')};
% this may be slow:
% opts.errFcn{2} = @(f,dual,x) rank(mat(x));
opts.stopCrit   = 4;
opts.tol    = 1e-8;
contOpts    = [];
contOpts.betaTol    = 10;
contOpts.maxIts     = 5;

epsilon = norm(b-data);  % cheating a bit...
x0      = [];
z0      = [];
mu = 5;

largescale  = ( n1*n2 >= 256^2 );
% obj     = prox_nuclear(1,largescale); % works, but unnecessarily general
obj     = prox_trace(1,largescale);

prox    = prox_l2(epsilon);
A   = linop_matrix( PAULI, 'C2R' );
I   = [];
It  = linop_handles({ [n1,n2],[n1*n2,1] }, vec, mat, 'C2C' );
A   = linop_compose( A, It );

[x,out,opts] = tfocs_SCD( obj,{ A, -b; I, 0 }, {prox, proj_psd}, mu, x0, z0, opts, contOpts );
X = mat(x);

fprintf('Error is %.2e, error after renormalizing is %.2e\n',...
    opts.errFcn{1}(1,1,X), opts.errFcn{1}(1,1,X/trace(X) ) );
fprintf('Rank of X is %d\n', rank(X) );

figure(1);
semilogy( out.err(:,1) );
hold all
semilogy(out.contLocations, out.err(out.contLocations,1), 'o' );

% TFOCS v1.3 by Stephen Becker, Emmanuel Candes, and Michael Grant.
% Copyright 2013 California Institute of Technology and CVX Research.
% See the file LICENSE for full license information.
