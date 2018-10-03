function op = linop_TV3D( sz, variation, action )

%LINOP_TV3D   3D Total-Variation (TV) linear operator.
%    OP = LINOP_TV3D( SZ ) returns a handle to a TFOCS linear operator that
%      implements the total variation linear operator on an M x N x P grid;
%      that is, to be applied to volume stacks of size [M,N,P].
%      By default, it expects to operate on M*N*P x 1 vectors
%      but if SZ = {M,N,P}, then expects to operate on M x N x P matrices
%
%    TV = LINOP_TV3D( X ) returns ||X||_TV  if X is bigger than 2 x 2 x 2
%
%    OP = LINOP_TV3D( SZ, VARIANT )
%       if VARIANT is 'regular' (default),
%               ... TODO
%       if VARIANT is 'circular',
%               ... TODO
%
%    [...] = LINOP_TV3D(SZ, VARIATION, ACTION )
%       if ACTION is 'handle', returns a TFOCS function handle (default)
%       if ACTION is 'cvx', returns a function handle suitable for CVX
%       if ACTION is 'matrix', returns the explicit TV matrix
%           (real part corresponds to horizontal differences,
%            imaginary part correspond to vertical differences)
%       if ACTION is 'norm', returns an estimate of the norm
%
%   Contributed by  Mahdi Hosseini (mahdi.hosseini@mail.utoronto.ca)
%   Has not been extensively tested

error(nargchk(1,3,nargin));
if nargin < 2 || isempty(variation), variation = 'regular'; end
if nargin < 3 || isempty(action), action = 'handle'; end

CALCULATE_TV = false;
if numel(sz) > 6
    CALCULATE_TV = true;
    X   = sz;
    sz  = size(X);
end
nDim = numel(sz);

if iscell(sz)
    n1 = sz{1};
    n2 = sz{2};
    n3 = sz{3};
else
    n1 = sz(1);
    n2 = sz(2);
    n3 = sz(3);
end

% Setup the Total-Variation operators
mat = @(x) reshape(x,n1,n2,n3);

if strcmpi(action,'matrix') || strcmpi(action,'cvx')
    I1 = eye(n1);
    I2 = eye(n2);
    I3 = eye(n3);
    switch lower(variation)
        case 'regular'
            e = ones(max([n1,n2,n3]),1);
            e2 = e;
            e2(n2:end) = 0;
            J = spdiags([-e2,e], 0:1,n2,n2);
            Dh = kron(I3,kron(J,I1));  % horizontal differences, sparse matrix
            % see also blkdiag
            
            e2 = e;
            e2(n1:end) = 0;
            J = spdiags([-e2,e], 0:1,n1,n1);
            Dv = kron(I3,kron(I2,J));  % vertical differences, sparse matrix
            
            e2 = e;
            e2(n3:end) = 0;
            J = spdiags([-e2,e], 0:1,n3,n3);
            Dd = kron(J,kron(I2,I1));  % Depth differences, sparse matrix
        case 'circular'
            e = ones(max([n1,n2,n3]),1);
            e2 = e;
            %             e2(n2:end) = 0;
            J = spdiags([-e2,e], 0:1,n2,n2);
            J(end,1) = 1;
            Dh = kron(I3, kron(J,I1));  % horizontal differences, sparse matrix
            % see also blkdiag
            
            e2 = e;
            %             e2(n1:end) = 0;
            J = spdiags([-e2,e], 0:1,n1,n1);
            J(end,1) = 1;
            Dv = kron(I3, kron(I2,J));  % vertical differences, sparse matrix
            
            e2 = e;
            %             e2(n1:end) = 0;
            J = spdiags([-e2,e], 0:1,n3,n3);
            J(end,1) = 1;
            Dd = kron(J, kron(I2,I1));  % vertical differences, sparse matrix
    end
    if strcmpi(action,'matrix')
        op = [Dh;Dv;Dd];
    else
        % "norms" is a CVX function
        op = @(X) sum( norms( [Dh*X(:), Dv*X(:), Dd*X(:)]' ) );
    end
    return;
end

switch lower(variation)
    case 'regular'
        Dh     = @(X) vec( [diff(X,1,2), zeros(n1,1,n3)] );
        Dv     = @(X) vec( [diff(X,1,1); zeros(1,n2,n3)] );
        Dd     = @(X) [vec(diff(X,1,3)); vec(zeros(n1,n2,1))];
        
        diff_h = @(X) [zeros(n1,1,n3),X(:,1:end-1,:)] - ...
            [X(:,1:end-1,:),zeros(n1,1,n3)];
        diff_v = @(X) [zeros(1,n2,n3);X(1:end-1,:,:)] - ...
            [X(1:end-1,:,:);zeros(1,n2,n3)];
        diff_d = @(X) mat([vec(zeros(n1,n2,1));vec(X(:,:,1:end-1))] - ...
            [vec(X(:,:,1:end-1));vec(zeros(n1,n2,1))]);
    case 'circular'
        % For circular version, 2 x 2 case is special.
        %         error('not yet implemented');
        Dh     = @(X) vec( [diff(X,1,2), X(:,1,:) - X(:,end,:)] );
        Dv     = @(X) vec( [diff(X,1,1); X(1,:,:) - X(end,:,:)] );
        Dd     = @(X) [vec(diff(X,1,3)); vec(X(:,:,1) - X(:,:,end))];
        % diff_h needs to be checked
        diff_h = @(X) [X(:,end,:),X(:,1:end-1,:)] - X;
        % diff_v needs to be checked
        diff_v = @(X) [X(end,:,:);X(1:end-1,:,:)] - X;
        % diff_d needs to be checked
        diff_d = @(X) mat([vec(X(:,:,end));vec(X(:,:,1:end-1))]) - X;
    otherwise
        error('Bad variation parameter');
end
if iscell(sz)
    Dh_transpose = @(X)      diff_h(mat(X))  ;
    Dv_transpose = @(X)      diff_v(mat(X))  ;
    Dd_transpose = @(X)      diff_d(mat(X))  ;
else
    Dh_transpose = @(X) vec( diff_h(mat(X)) );
    Dv_transpose = @(X) vec( diff_v(mat(X)) );
    Dd_transpose = @(X) vec( diff_d(mat(X)) );
end

%%  TV & TVt Definitions
TV  = @(x) [Dh(mat(x)); Dv(mat(x)); Dd(mat(x))];

firstThird = @(x) x(1: n1*n2*n3);
secondThird= @(x) x(n1*n2*n3+1: 2*n1*n2*n3);
thirdThird= @(x) x(2*n1*n2*n3+1: 3*n1*n2*n3);
TVt = @(z) ( Dh_transpose(firstThird(z)) +...
    Dv_transpose(secondThird(z)) +...
    Dd_transpose(thirdThird(z)));

%%
if CALCULATE_TV
    op = norm( TV(X), 1 );
    return;
end

if strcmpi(action,'norm')
    % to compute max eigenvalue, I use a vector
    % that is very likely to be the max eigenvector:
    %  matrix with every entry alternating -1 and 1
    even = @(n) ~( n - 2*round(n/2) );  % returns 1 if even, 0 if odd
    Y = zeros( n1 + even(n1), n2 + even(n2), n3 + even(n3) );
    nn = numel(Y);
    Y(:) = (-1).^(1:nn);
    Y = Y(1:n1,1:n2,1:n3);
    op = norm( TV(Y) )/norm(Y(:));
    
    % Nearly equivalent to:
    % norm(full( [real(tv); imag(tv)] ) )
    % where tv is the matrix form
else
    if iscell(sz)
        szW = { [n1,n2,n3], [n1*n2*n3,1] };
    else
        szW = prod(sz); % n1 * n2
        szW = [nDim*szW, nDim*szW];
    end
    op = @(x,mode)linop_tv_r2c(szW,TV,TVt,x,mode);
end

function y = linop_tv_r2c( sz, TV, TVt, x, mode )
switch mode,
    case 0, y = sz;
    case 1, y = TV( realcheck( x ) );
    case 2, y = realcheck( TVt( x ) );
end

function y = realcheck( y )
if ~isreal( y ),
    error( 'Unexpected complex value in linear operation.' );
end

% TFOCS v1.3 by Stephen Becker, Emmanuel Candes, and Michael Grant.
% Copyright 2013 California Institute of Technology and CVX Research.
% See the file LICENSE for full license information.
