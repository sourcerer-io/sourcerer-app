%{
    Via smoothing, TFOCS can solve a Semi-definite Program (SDP) in standard form:

(P)     min <C,X> s.t. X >= 0, A(X)=b


    This extends to LP as well (see test_LinearProgram.m )
    We can also solve the dual of SDP, which is LMI. See test_LMI.m
%}

% Add TFOCS to your path.

randn('state',9243); rand('state',234324');

N = 80;
M = round(N^2/2);
X = randn(N); X = X*X';
A = sprand(M,N^2,.005); 
C = randn(N); C = C + C';
vec = @(X) X(:);
mat = @(y) reshape(y,N,N);
% Important: we want each row of A to be the vectorized form of the
%   symmetric matrix A_i.  Otherwise, the dual problem makes no sense.
%  Here, we'll ensure this symmetry.
% (BTW, due to how Matlab stores sparse arrays, we only want to make
%  column operations. So we'll operate on A' and then transpose back)
At = A';
for row = 1:M
    At(:,row) = vec( mat(At(:,row)) + mat(At(:,row))' )/2;
end
A = At'; clear At;

b = A*vec(X);

normA = normest(A);

fileName = fullfile('reference_solutions','SDP');
if exist([fileName,'.mat'],'file')
    load(fileName);
    fprintf('Loaded problem from %s\n', fileName );
else
    cvx_begin sdp
        variable X(N,N) symmetric
        minimize trace( C*X )
        subject to
            X >= 0
            A*vec(X) == b
    cvx_end
    X_cvx = X;
    save(fullfile(pwd,fileName),'X_cvx');
    fprintf('Saved data to file %s\n', fileName);
end

%% solve in TFOCS

opts = [];
opts.errFcn        = {@(f,d,X) norm( X - X_cvx,'fro')/norm(X_cvx,'fro' )};  % optional
% opts.errFcn{end+1} =  @(f,d,X) norm( A*vec(X) - b )/norm(b);  % optional
opts.restart = 2000;
opts.continuation = true;
x0   = [];
z0   = [];
mu = 1;

opts.stopCrit   = 4;
opts.tol        = 1e-4;
contOpts        = [];       % options for "continuation" settings
%   (to see possible options, type "continuation()" )
%    By changing the options, you can get much better results sometimes,
%    but here we use default choices for simplicity.
% contOpts.accel  = false;
% contOpts.betaTol    = 10;
% contOpts.finalTol = 1e-10;

opts.normA      = normA; % this will help with scaling
[x,out,optsOut] = solver_sSDP(C,A,b, mu, x0, z0, opts, contOpts);
% Check that we are within allowable bounds
if out.err(end) < 5e-2
    disp('Everything is working');
else
    error('Failed the test');
end
%% Here's another simple example, using complex valued variables
randn('state',9243); rand('state',234324');

N = 20;
M = round(N^2/1.3);
X = randn(N) + 1i*randn(N); X = X*X';       % ensure Hermitian and pos. semi-def.
A = sprandn(M,N^2,.01) + 1i*sprandn(M,N^2,.01);
C = randn(N)+1i*randn(N); C = C + C';       % ensure Hermitian
vec = @(X) X(:);
mat = @(y) reshape(y,N,N);
% Same as before...
At = A';
for row = 1:M
    At(:,row) = vec( mat(At(:,row)) + mat(At(:,row))' )/2;
end
A = At'; clear At;

% Note: b should be real, but due to round errors it has as small imaginary part
b = real(A*vec(X));

normA = linop_normest(A);
fileName = 'reference_solutions/SDP_complex';
if exist([fileName,'.mat'],'file')
    load(fileName);
    fprintf('Loaded problem from %s\n', fileName );
else
    cvx_begin sdp
        variable X(N,N) hermitian % note the change from symmetric to hermitian
        minimize real(trace( C*X )) % this should be real, but there are rounding errors
        subject to
            X >= 0
            real(A*vec(X)) == b
    cvx_end
    X_cvx = X;
    save(fullfile(pwd,fileName),'X_cvx');
    fprintf('Saved data to file %s\n', fileName);
end

% and solve with TFOCS
opts = [];
opts.errFcn        = {@(f,d,X) norm( X - X_cvx,'fro')/norm(X_cvx,'fro' )};
opts.continuation = true;
x0   = [];
z0   = [];
mu = 1e-3;
% opts.cmode      = 'C2R'; % explicitly tell it that we are complex. not necessary though
opts.normA      = normA; % this will help with scaling
opts.stopCrit   = 4;
opts.tol        = 1e-4;
[x,out,optsOut] = solver_sSDP(C,A,b, mu, x0, z0, opts, contOpts);

% Check that we are within allowable bounds
if out.err(end) < 5e-2
    disp('Everything is working');
else
    error('Failed the test');
end

% TFOCS v1.3 by Stephen Becker, Emmanuel Candes, and Michael Grant.
% Copyright 2013 California Institute of Technology and CVX Research.
% See the file LICENSE for full license information.
