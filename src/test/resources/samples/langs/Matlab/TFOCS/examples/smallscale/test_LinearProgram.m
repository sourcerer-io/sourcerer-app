%{
    Via smoothing, TFOCS can solve a Linear Program (LP) in standard form:

(P)     min c'x s.t. x >= 0, Ax=b


    This extends to SDP as well (see test_SDP.m )
%}

% Add TFOCS to your path.

randn('state',9243); rand('state',234324');

N = 5000;
M = round(N/2);
x = randn(N,1)+10;
A = sprand(M,N,.01);
c = randn(N,1);
b = A*x;
if issparse(A)
    normA   = normest(A);
else
    normA = norm(A);
end

fileName = fullfile('reference_solutions','LP');
if exist([fileName,'.mat'],'file')
    load(fileName);
    fprintf('Loaded problem from %s\n', fileName );
else
    cvx_begin
        variable x(N)
        minimize( c'*x )
        subject to
            x >= 0
            A*x == b
    cvx_end
    x_cvx = x;
    save(fullfile(pwd,fileName),'x_cvx');
    fprintf('Saved data to file %s\n', fileName);
end

%% solve in TFOCS

opts = [];
opts.errFcn        = {@(f,d,x) norm( x - x_cvx )/norm(x_cvx )};  % optional
% opts.errFcn{end+1} =  @(f,d,x) norm( A*x - b )/norm(b );  % optional
opts.restart = 2000;
opts.continuation = true;
x0   = [];
z0   = [];
mu = 1e-2;
mu = 1e-3;

opts.stopCrit   = 4;
opts.tol        = 1e-4;
contOpts        = [];       % options for "continuation" settings
%   (to see possible options, type "continuation()" )
%    By changing the options, you can get much better results sometimes,
%    but here we use default choices for simplicity.
% contOpts.accel  = false;
% contOpts.betaTol    = 10;
% contOpts.finalTol = 1e-10;
contOpts.maxIts     = 10;
contOpts.initialTol = 1e-3;

opts.normA      = normA; % this will help with scaling
[x,out,optsOut] = solver_sLP(c,A,b, mu, x0, z0, opts, contOpts);
% Check that we are within allowable bounds
if out.err(end) < 7e-2
    disp('Everything is working');
else
    error('Failed the test');
end
%% plot
figure(2);
semilogy( out.err(:,1) );


%% == TFOCS can also handle LPs with box constraints ==========
randn('state',9243); rand('state',234324');

N = 3000;
M = round(N/2);
x = randn(N,1)+10;
A = sprand(M,N,.01);
c = randn(N,1);
b = A*x;
% There is no longer an automatic x >= 0 bound
%   (if you want to impose this, incorporate it into the lower bound)
l = -2*ones(N,1); % lower bound
u = 13*ones(N,1); % upper bound
if issparse(A)
    normA   = normest(A);
else
    normA = norm(A);
end

fileName = fullfile('reference_solutions','LP_box');
if exist([fileName,'.mat'],'file')
    load(fileName);
    fprintf('Loaded problem from %s\n', fileName );
else
    cvx_begin
        variable x(N)
        cvx_precision best
        minimize( c'*x )
        subject to
            x >= l
            x <= u
            A*x == b
    cvx_end
    x_cvx = x;
    save(fullfile(pwd,fileName),'x_cvx');
    fprintf('Saved data to file %s\n', fileName);
end

%% solve box-constrained version in TFOCS

opts = [];
opts.errFcn        = {@(f,d,x) norm( x - x_cvx )/norm(x_cvx )};  % optional
opts.restart = 2000;
opts.continuation = true;
x0   = [];
z0   = [];
mu = 1e-2;

opts.stopCrit   = 4;
opts.tol        = 1e-5;
contOpts        = [];       % options for "continuation" settings
contOpts.maxIts     = 5;
contOpts.muDecrement = .8;
% contOpts.accel  = false;

opts.normA      = normA; % this will help with scaling
[x,out,optsOut] = solver_sLP_box(c,A,b,l,u,mu, x0, z0, opts, contOpts);

% Check that we are within allowable bounds
if out.err(end) < 2e-2
    disp('Everything is working');
else
    error('Failed the test');
end

%% plot box-constrained version
figure(2);
semilogy( out.err(:,1) );

%% close figures
close all

% TFOCS v1.3 by Stephen Becker, Emmanuel Candes, and Michael Grant.
% Copyright 2013 California Institute of Technology and CVX Research.
% See the file LICENSE for full license information.
