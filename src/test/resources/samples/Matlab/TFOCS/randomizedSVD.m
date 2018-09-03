function [U,S,V] = randomizedSVD( X, r, rEst, nPower, seed, opts )
% [U,S,V] = randomizedSVD( X, r, rEst, nPower, seed, opts )
%   returns V, S such that X ~ U*S*V' ( a m x n matrix)
%   where S is a r x r matrix
%   rEst >= r is the size of the random multiplies (default: ceil(r+log2(r)) )
%   nPower is number of iterations to do the power method
%    (should be at least 1, which is the default)
%   seed can be the empty matrix; otherwise, it will be used to seed
%       the random number generator (useful if you want reproducible results)
%   opts is a structure containing further options, including:
%       opts.warmStart  Set this to a matrix if you have a good estimate
%           of the row-space of the matrix already. By default,
%           a random matrix is used.
%
%   X can either be a m x n matrix, or it can be a cell array
%       of the form {@(y)X*y, @(y)X'*y, n }
%
% Follows the algorithm from [1]
%
% [1] "Finding Structure with Randomness: Probabilistic Algorithms 
% for Constructing Approximate Matrix Decompositions"
% by N. Halko, P. G. Martinsson, and J. A. Tropp. SIAM Review vol 53 2011.
% http://epubs.siam.org/doi/abs/10.1137/090771806
%

% added to TFOCS in October 2014

if isnumeric( X )
    X_forward = @(y) X*y;
    X_transpose = @(y) X'*y;
    n   = size(X,2);
elseif iscell(X)
    if isa(X{1},'function_handle')
        X_forward = X{1};
    else
        error('X{1} should be a function handle');
    end
    if isa(X{2},'function_handle')
        X_transpose = X{2};
    else
        error('X{2} should be a function handle');
    end
    if size(X) < 3
        error('Please specify X in the form {@(y)X*y, @(y)X''*y, n }' );
    end
    n = X{3};
else
    error('Unknown type for X: should be matrix or cell/function handle'); 
end
function out = setOpts( field, default )
    if ~isfield( opts, field )
        out = default;
    else
        out = opts.(field);
    end
end

% If you want reproducible results for some reason:
if nargin >= 6 && ~isempty(seed)
    % around 2013 or 14 (not sure exactly)
    %   they start changing .setDefaultStream...
    if verLessThan('matlab','8.2')
        RandStream.setDefaultStream(RandStream('mt19937ar', 'seed', seed) );
    else
        RandStream.setGlobalStream(RandStream('mt19937ar', 'seed', seed) );
    end
end
if nargin < 3 || isempty( rEst )
    rEst =  ceil( r + log2(r) ); % for example...
    rEst = min( rEst, n );
end
if nargin < 4 || isempty( nPower )
    nPower = 1;
end
if nPower < 1, error('nPower must be >= 1'); end
if nargin < 6, opts = []; end

warmStart   = setOpts('warmStart',[] );
if isempty( warmStart )
    Q   = randn( n, rEst );
else
    Q   = warmStart; 
    if size(Q,1) ~= n, error('bad height dimension for warmStart'); end
    if size(Q,2) > rEst
        % with Nesterov, we get this a lot, so disable it
        warning('randomizedSVD:warmStartLarge','Warning: warmStart has more columns than rEst');
%         disp('Warning: warmStart has more columns than rEst');
    else
        Q   = [Q, randn(n,rEst - size(Q,2)  )];
    end
end
Q   = X_forward(Q);
% Algo 4.4 in "Structure in randomness" paper, but we re-arrange a little
for j = 1:(nPower-1)
    [Q,R] = qr(Q,0);
    Q   = X_transpose(Q);
    [Q,R] = qr(Q,0);
    Q   = X_forward(Q);
end
[Q,R] = qr(Q,0);
    
% We can now approximate:
%   X ~ QQ'X = QV'
% Form Q'X, e.g. V = X'Q
V   = X_transpose(Q);

[V,R] = qr(V,0);
[U,S,VV] = svd(R','econ');
U   = Q*U;
V   = V*VV;

% Now, pick out top r. It's already sorted.
U   = U(:,1:r);
V   = V(:,1:r);
S   = S(1:r,1:r);


end % end of function
