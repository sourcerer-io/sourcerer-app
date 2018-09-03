%{
Test the trace-constrained least-squares problem with positive
semi-definite matrix variables

     minimize (1/2)*norm( A * X - b )^2 
     with the constraint that X is positive semi-definite ( X >= 0 )
and optionally,
    the constraint trace(X) <= lambda

%}

% Try to load the problem from disk
fileName = fullfile('reference_solutions','traceLS_problem2_noisy');
if exist([fileName,'.mat'],'file')
    load(fileName);
    fprintf('Loaded problem from %s\n', fileName );
else
    % Generate a new problem
    randn('state',sum('Trace')+5);
    rand('state',sum('Trace2')+5);
    
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
    noise = EPS * randn(k,1);  % this destroys symmetry...
    b = b_original + noise;
    lambda       = trace( X_original );
    objective    = @(X) sum_square( X(omega) - b )/2;
    obj_original = objective(X_original);

    % get references via CVX
    cvx_begin
        cvx_precision best
        cvx_quiet true
        variable Xcvx(N,N)
        minimize objective(Xcvx)
        subject to
            Xcvx == semidefinite(N)
    cvx_end
    X_reference_noTraceConstraint = Xcvx; 
        fprintf('Difference between convex solution (no trace constraint) and original signal: %.2e\n', ...
        norm( Xcvx - X_original, 'fro' ) );
    
    cvx_begin
        cvx_precision best
        cvx_quiet true
        variable Xcvx(N,N)
        minimize objective(Xcvx)
        subject to
            Xcvx == semidefinite(N)
            trace(Xcvx) <= lambda
    cvx_end
    X_reference = Xcvx;         % the trace norm minimizer   
    obj_reference = objective(X_reference);
    fprintf('Difference between convex solution (with trace constraint) and original signal: %.2e\n', ...
        norm( Xcvx - X_original, 'fro' ) );
    save(fileName,'X_original','X_reference','X_reference_noTraceConstraint',...
        'omega','b','obj_original',...
        'Left','EPS','b_original','R','obj_reference','lambda');
    fprintf('Saved data to file %s\n', fileName);
    
end

[M,N]            = size(X_reference);
norm_X_reference = norm(X_reference,'fro');
er_reference     = @(x) norm(x-X_reference,'fro')/norm_X_reference;
norm_X_reference2= norm(X_reference_noTraceConstraint,'fro');
er_reference2    = @(x) norm(x-X_reference_noTraceConstraint,'fro')/norm_X_reference2;
objective        = @(X) norm( X(omega) - b )^2/2;

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
%% Solve unconstrained version. No smoothing is necessary!
opts = struct('maxIts',500);
opts.errFcn{1} = @(f,x) er_reference2(x); % no trace constraint
opts.errFcn{2} = @(f,x) sum( abs(eig(x)) > 1e-5 ); % numerical rank
% tell it to use eigs instead of eig
% opts.largescale = true; % ( but not recommended)

% opts.symmetrize = true; % another option

A = sparse( omegaI,omegaJ,b,N,N);
[x,out] = solver_psdComp( A, opts );
% Note: we do not expect to get zero error because there might be more
%   than one optimal solution for this problem (since there are not
%   so many constraints)
% Check that we have a feasible solution
fprintf('Objective is %.2e, min eigenvalue is %.2e\n', objective(x),...
    min(eig(x)) );
%% Solve trace constrained version. No smoothing necessary!
opts = struct('maxIts',1500,'tol',1e-9);
opts.errFcn{1} = @(f,x) er_reference(x); % no trace constraint
opts.errFcn{2} = @(f,x) trace(x)-lambda;
opts.errFcn{3} = @(f,x) sum( abs(eig(x)) > 1e-5 ); % numerical rank
% we can also symmetrize "omega", but it makes little difference,
%   and gives slightly differen value than CVX, since CVX symmetrizes
%   differently:
% opts.symmetrize = true;
A = sparse( omegaI,omegaJ,b,N,N);
[x,out] = solver_psdCompConstrainedTrace( A,lambda, opts );

h=figure();
semilogy(out.err(:,1));

% Check that we are within allowable bounds
if out.err(end,1) < 1e-5
    disp('Everything is working');
else
    error('Failed the test');
end

%%
close(h)
% TFOCS v1.3 by Stephen Becker, Emmanuel Candes, and Michael Grant.
% Copyright 2013 California Institute of Technology and CVX Research.
% See the file LICENSE for full license information.
