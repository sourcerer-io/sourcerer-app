%{
    Via smoothing, TFOCS can solve Linear Matrix Inequalities (LMI)
    (these are equivalent to the dual of a SDP in standard form)

    min_y  <b,y>
    s.t.    A_0 + sum_i=1^M  A_i * y(i) >= 0

where ">=" refers to the positive semi-definite cone.
"b" and "y" are vectors of length M,
and A_i (i = 0, 1, ..., M)
are symmetric or Hermian matrices of size N x N
(where M <= N^2 )

TFOCS assumes that all the A_i matrices (i=1,...,M; the A_0 matrix is
handled separately) are efficiently stored in one big "A" matrix
so that we can compactly replace the sum_i A_i * y(i)
with mat( A'*y ), where mat() is a reshaping operator.
The code below shows how we do this.

    See also test_SDP.m

    If we identify A0 with -C, then this is the dual of the SDP in standard form.

%}

% Add TFOCS to your path.

randn('state',9243); rand('state',23432);

N = 30;
M = round(N^2/4);

symmetrize  = @(X) (X+X')/2;
vec         = @(X) X(:);
mat         = @(y) reshape(y,N,N);

Acell = cell(M,1);
for m = 1:M
    Acell{m} = symmetrize( randn(N) );
end

% Put "Acell" into a matrix:
A = zeros(M,N^2);
for m = 1:M
    A(m,:) = vec( Acell{m} );
end
normA = normest(A,1e-2);

b = randn(M,1);
y = randn(M,1); 
A0 = mat(A'*y); % want A0 in range of A', otherwise infeasible or unbounded

fileName = fullfile('reference_solutions','LMI');
if exist([fileName,'.mat'],'file')
    load(fileName);
    fprintf('Loaded problem from %s\n', fileName );
else
    cvx_begin
        variable y(M)
        minimize( b'*y )
        subject to
            A0 + mat(A'*y) >= 0
    cvx_end
    y_cvx = y;
    save(fullfile(pwd,fileName),'y_cvx');
    fprintf('Saved data to file %s\n', fileName);
end

%% solve via TFOCS
mu = 1e-3;
opts = [];
opts.errFcn = @(f,d,y) norm( y - y_cvx)/norm(y_cvx);

y0 = []; z0 = [];
[yy, out, opts ] = solver_sLMI( A0, A, b, mu, y0, z0, opts );

% Check that we are within allowable bounds
if out.err(end) < 1e-8
    disp('Everything is working');
else
    error('Failed the test');
end

%% Version with complex variables:
randn('state',9243); rand('state',23432);
N = 30;
M = round(N^2/4);
Acell = cell(M,1);
for m = 1:M
    Acell{m} = symmetrize( randn(N) + 1i*randn(N) );
end
A = zeros(M,N^2);
for m = 1:M
    A(m,:) = vec( Acell{m} );
end
normA = normest(A,1e-2);

b = randn(M,1);     % this should always be real
y = randn(M,1);     % this should always be real
A0 = mat(A'*y);     % this may be complex

fileName = 'reference_solutions/LMI_complex';
if exist([fileName,'.mat'],'file')
    load(fileName);
    fprintf('Loaded problem from %s\n', fileName );
else
    cvx_begin
        variable y(M)
        minimize( b'*y )
        subject to
            A0 + mat(A'*y) == semidefinite(N)
    cvx_end
    y_cvx = y;
    save(fullfile(pwd,fileName),'y_cvx');
    fprintf('Saved data to file %s\n', fileName);
end

% and solve via TFOCS:
mu = 1e-3;
opts = [];
opts.errFcn = @(f,d,y) norm( y - y_cvx)/norm(y_cvx);
y0 = []; z0 = [];
[yy, out, opts ] = solver_sLMI( A0, A, b, mu, y0, z0, opts );

% Check that we are within allowable bounds
if out.err(end) < 1e-8
    disp('Everything is working');
else
    error('Failed the test');
end

% TFOCS v1.3 by Stephen Becker, Emmanuel Candes, and Michael Grant.
% Copyright 2013 California Institute of Technology and CVX Research.
% See the file LICENSE for full license information.
