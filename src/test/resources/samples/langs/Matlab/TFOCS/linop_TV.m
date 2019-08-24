function op = linop_TV( sz, variation, action )

%LINOP_TV   2D Total-Variation (TV) linear operator.
%    OP = LINOP_TV( SZ ) returns a handle to a TFOCS linear operator that
%      implements the total variation linear operator on an M x N grid;
%      that is, to be applied to matrices of size [M,N].
%      By default, it expects to operate on M*N x 1 vectors
%      but if SZ = {M,N}, then expects to operate on M x N matrices
%
%      N.B. In this form, OP does not calculate the TV norm but rather
%       a vector of size M*N x 1 such that TV(X) = norm( OP(X,1), 1 ).
%
%    TV = LINOP_TV( X ) returns ||X||_TV  if X is bigger than 2 x 2
%
%    OP = LINOP_TV( SZ, VARIANT ) 
%       if VARIANT is 'regular' (default),
%           assumes zeros on the boundary (Dirichlet boundary conditions)
%       if VARIANT is 'circular',
%           assumes circularity, so x(:,N+1) - x(:,N)
%           is calculated by x(:,1) - x(:,N) (and similarly
%           for row differences) [when SZ={M,N}]
%
%    [...] = LINOP_TV(SZ, VARIATION, ACTION )
%       if ACTION is 'handle', returns a TFOCS function handle (default)
%       if ACTION is 'cvx', returns a function handle suitable for CVX
%       if ACTION is 'matrix', returns the explicit TV matrix
%           (real part corresponds to horizontal differences,
%            imaginary part correspond to vertical differences)
%       if ACTION is 'norm', returns an estimate of the norm
%
%   TODO: check circular case for non-square domains
%

error(nargchk(1,3,nargin));
if nargin < 2 || isempty(variation), variation = 'regular'; end
if nargin < 3 || isempty(action), action = 'handle'; end

CALCULATE_TV = false;
if numel(sz) > 4 
    CALCULATE_TV = true;
    X   = sz;
    sz  = size(X);
end

if iscell(sz)
    n1 = sz{1};
    n2 = sz{2};
else
    n1 = sz(1);
    n2 = sz(2);
end

% Setup the Total-Variation operators
mat = @(x) reshape(x,n1,n2);

if strcmpi(action,'matrix') || strcmpi(action,'cvx')
    switch lower(variation)
        case 'regular'
            e = ones(max(n1,n2),1);
            e2 = e;
            e2(n2:end) = 0;
            J = spdiags([-e2,e], 0:1,n2,n2);
            I = eye(n1);
            Dh = kron(J,I);  % horizontal differences, sparse matrix
            % see also blkdiag
            
            e2 = e;
            e2(n1:end) = 0;
            J = spdiags([-e2,e], 0:1,n1,n1);
            I = eye(n2);
            Dv = kron(I,J);  % vertical differences, sparse matrix
        case 'circular'
            e = ones(max(n1,n2),1);
            e2 = e;
%             e2(n2:end) = 0;
            J = spdiags([-e2,e], 0:1,n2,n2);
            J(end,1) = 1;
            I = eye(n1);
            Dh = kron(J,I);  % horizontal differences, sparse matrix
            % see also blkdiag
            
            e = ones(max(n1,n2),1);
            e2 = e;
%             e2(n1:end) = 0;
            J = spdiags([-e2,e], 0:1,n1,n1);
            J(end,1) = 1;
            I = eye(n2);
            Dv = kron(I,J);  % vertical differences, sparse matrix
    end
    if strcmpi(action,'matrix')
        op = Dh + 1i*Dv;
    else
        % "norms" is a CVX function, but we can over-load it (see sub-function below)
        op = @(X) sum( norms( [Dh*X(:), Dv*X(:)]', 1 ) );
    end
    return;
end

switch lower(variation)
    case 'regular'
        Dh     = @(X) vec( [diff(X,1,2),  zeros(n1,1)] );
        diff_h = @(X) [zeros(n1,1),X(:,1:end-1)] - [X(:,1:end-1),zeros(n1,1) ];
        Dv     = @(X) vec( [diff(X,1,1); zeros(1,n2)] );
        diff_v = @(X) [zeros(1,n2);X(1:end-1,:)] - [X(1:end-1,:);zeros(1,n2) ];
        % sometimes diff_v is much slower than diff_h
        % We can exploit data locality by working with transposes
        diff_v_t = @(Xt) ([zeros(n2,1),Xt(:,1:end-1)] - [Xt(:,1:end-1),zeros(n2,1)])';
    case 'circular'
        % For circular version, 2 x 2 case is special.
%         error('not yet implemented');
        Dh     = @(X) vec( [diff(X,1,2),  X(:,1) - X(:,end)] );
        % diff_h needs to be checked
        diff_h = @(X) [X(:,end),X(:,1:end-1)] - X;
        % diff_v needs to be checked
        Dv     = @(X) vec( [diff(X,1,1); X(1,:) - X(end,:) ] );
        diff_v = @(X) [X(end,:);X(1:end-1,:)] - X;
        diff_v_t = @(Xt) ([Xt(:,end),Xt(:,1:end-1)] - Xt)';
    otherwise
        error('Bad variation parameter');
end
if iscell(sz)
    Dh_transpose = @(X)      diff_h(mat(X))  ;
%     Dv_transpose = @(X)      diff_v(mat(X))  ;
    Dv_transpose = @(X)      diff_v_t(mat(X)')  ; % faster
else
    Dh_transpose = @(X) vec( diff_h(mat(X)) );
%     Dv_transpose = @(X) vec( diff_v(mat(X)) );
    Dv_transpose = @(X) vec( diff_v_t(mat(X)') ); % faster
end

TV  = @(x) ( Dh(mat(x)) + 1i*Dv(mat(x)) );     % real to complex
TVt = @(z) ( Dh_transpose(real(z)) + Dv_transpose(imag(z)) );

if CALCULATE_TV
    op = norm( TV(X), 1 );
    return;
end

if strcmpi(action,'norm')
    % to compute max eigenvalue, I use a vector
    % that is very likely to be the max eigenvector:
    %  matrix with every entry alternating -1 and 1
    even = @(n) ~( n - 2*round(n/2) );  % returns 1 if even, 0 if odd
    Y = zeros( n1 + even(n1), n2 + even(n2) );
    nn = numel(Y);
    Y(:) = (-1).^(1:nn);
    Y = Y(1:n1,1:n2);
    op = norm( TV(Y) )/norm(Y(:));
    
    % Nearly equivalent to:
    % norm(full( [real(tv); imag(tv)] ) ) 
    % where tv is the matrix form
else
    if iscell(sz)
        szW = { [n1,n2], [n1*n2,1] };
    else
        szW = sz(1)*sz(2); % n1 * n2
        szW = [szW,szW];
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


function y = norms( x, p, dim )
sx = size(x);
if nargin < 3, dim = 1; end
if nargin < 2 || isempty(p), p = 2; end
if isempty(x) || dim > length(sx) || sx(dim)==1
    p = 1;
end
switch p,
    case 1,
        y = sum( abs( x ), dim );
    case 2,
        y = sqrt( sum( x .* conj( x ), dim ) );
    case Inf,
        y = max( abs( x ), [], dim );
    case {'Inf','inf'}
        y = max( abs( x ), [], dim );
    otherwise,
        y = sum( abs( x ) .^ p, dim ) .^ ( 1 / p );
end


% TFOCS v1.3 by Stephen Becker, Emmanuel Candes, and Michael Grant.
% Copyright 2013 California Institute of Technology and CVX Research.
% See the file LICENSE for full license information.
