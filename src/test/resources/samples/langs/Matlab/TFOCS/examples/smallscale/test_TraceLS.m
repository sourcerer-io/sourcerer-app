%{
Test the trace-constrained least-squares problem with positive
semi-definite matrix variables

     minimize (1/2)*norm( A * X - b )^2 + lambda * trace( X )
     with the constraint that X is positive semi-definite ( X >= 0 )
%}

% Try to load the problem from disk
fileName = fullfile('reference_solutions','traceLS_problem1_noisy');
if exist([fileName,'.mat'],'file')
    load(fileName);
    fprintf('Loaded problem from %s\n', fileName );
else
    % Generate a new problem

    randn('state',sum('Trace'));
    rand('state',sum('Trace2'));
    
    N = 30; R = 2;
    
    df = R*N;
    oversample = 5;
    Left  = randn(M,R);
    Right = Left;
    k = round(oversample*df); 
    k = min( k, round(.8*N*N) );
    omega = randperm(N*N);
    omega = sort(omega(1:k)).';

    X_original = Left*Right';       % the "original" signal -- may not be optimal value
    b_original = X_original(omega); 
    EPS = .001;        % noise level
    noise = EPS * randn(k,1);
    b = b_original + noise;
    lambda       = 1e-2;
    objective    = @(X) sum_square( X(omega) - b )/2 + lambda*trace(X);
    obj_original = objective(X_original);

    % get reference via CVX
    cvx_begin
        cvx_precision best
        cvx_quiet true
        variable Xcvx(N,N)
        minimize objective(Xcvx)
        subject to
            Xcvx == semidefinite(N)
    cvx_end
    X_reference = Xcvx;         % the nuclear norm minimizer
    obj_reference = objective(X_reference);
    fprintf('Difference between convex solution and original signal: %.2e\n', ...
        norm( Xcvx - X_original, 'fro' ) );
    save(fileName,'X_original','X_reference','omega','b','obj_original',...
        'Left','EPS','b_original','R','obj_reference','lambda');
    fprintf('Saved data to file %s\n', fileName);
    
end

[M,N]            = size(X_reference);
norm_X_reference = norm(X_reference,'fro');
er_reference     = @(x) norm(x-X_reference,'fro')/norm_X_reference;
objective        = @(X) norm( X(omega) - b )^2/2 + lambda*trace(X);

[omegaI,omegaJ] = ind2sub([M,N],omega);
mat = @(x) reshape(x,M,N);
vec = @(x) x(:);
    
k  = length(omega);
p  = k/(M*N);
df = R*(M+N-R);
fprintf('%d x %d rank %d matrix, observe %d = %.1f x df = %.1f%% entries\n',...
    M,N,R,k,k/df,p*100);
fprintf(' Trace norm solution and original matrix differ by %.2e\n',...
    norm(X_reference-X_original,'fro')/norm_X_reference );
%% Solve. No smoothing is necessary!
opts = struct('tol',1e-12);
opts.errFcn = @(f,x) er_reference(x);
x0          = [];
% opts.debug  = true;

% we need to tell it how to subsample. One method:
A = linop_subsample( {[N,N],[k,1]}, omega );

% another method: make a matrix with the correct
%   sparsity pattern and let solver_TraceLS do it for us
% A = sparse( omegaI,omegaJ,ones(k,1),N,N);

[x,out] = solver_TraceLS( A, b, lambda, x0, opts );
epsilon = norm( x(omega) - b );
h=figure();
semilogy(out.err);

% Check that we are within allowable bounds
if out.err(end) < 1e-5
    disp('Everything is working');
else
    error('Failed the test');
end
%% We can solve this via a smoothed nuclear norm formulation
%  But it will be slower!
%  Also, it will not enforce the positive semi-definite constraint,
%  so it is not exactly the same.

testOptions = {};
opts = [];
opts.errFcn = @(f,dual,x) er_reference(x);
opts.continuation       = true;
opts.stopCrit   = 4;
opts.tol        = 1e-6;

mu      = .01;
X0      = 0; 

% [ x, out, opts ] = solver_sNuclearBP( {M,N,omega}, b, mu, X0, [], opts ); 
[ x, out, opts ] = solver_sNuclearBPDN( {M,N,omega}, b, epsilon, mu, X0, [], opts ); 

%%
close(h)
% TFOCS v1.3 by Stephen Becker, Emmanuel Candes, and Michael Grant.
% Copyright 2013 California Institute of Technology and CVX Research.
% See the file LICENSE for full license information.
