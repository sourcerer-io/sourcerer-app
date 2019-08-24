function op = proj_spectral( q, SYM_FLAG, LARGESCALE )

%PROJ_SPECTRAL Projection onto the set of matrices with spectral norm less than or equal to q
%    OP = PROJ_SPECTRAL( q ) returns a function that implements the
%    indicator for matrices with spectral norm less than q.
%    Q is optional; if omitted, Q=1 is assumed. But if Q is supplied, 
%    it must be a positive real scalar.
%    This function is like proj_psdUTrace.m but does not assume
%    that inputs are square Hermitian positive semidefinite matrices.
%   OP = PROJ_SPECTRAL( q, 'sym' ) or OP = PROJ_SPECTRAL( 'eig' )
%    will instruct the code that the matrix is Hermitian and 
%    therefore the relations between singular- and eigen-values
%    are well known, and the code will use the more efficient
%    eigenvalue decomposition (instead of the SVD).
%   OP = PROJ_SPECTRAL( ..., largescale) will switch to using
%    svds (or PROPACK, if installed and in the path) or eigs
%    instead of svd or eig, if largescale==true. This is usually
%    beneficial for large, sparse variables.
%
% Dual: prox_nuclear(q)
%   (if domain is pos. semidefinite matrices, then prox_trace(q)
%    is also the dual, and is more efficient than prox_nuclear(q) ).
%
% See also prox_nuclear, proj_linf, proj_nuclear, prox_spectral, proj_maxEig

% Sept 1, 2012
if nargin < 3 || isempty(LARGESCALE)
    LARGESCALE  = false;
end

if nargin == 0,
	q = 1;
elseif ~isnumeric( q ) || ~isreal( q ) || numel( q ) ~= 1 || q <= 0,
	error( 'Argument must be positive.' );
end
vectorFunction = proj_linf( q );
if nargin >= 2 && ( ...
        ~isempty(strfind(lower(SYM_FLAG),'eig')) || ...
        ~isempty(strfind(lower(SYM_FLAG),'sym')) )
    if LARGESCALE
        % clear the persistent values:
        proj_spectral_eigs_q();
        op = @(varargin)proj_spectral_eigs_q( q,vectorFunction, varargin{:} );
    else
        op = @(varargin)proj_spectral_eig_q( q,vectorFunction, varargin{:} );
    end
else
    if LARGESCALE
        % clear the persistent values:
        proj_spectral_svds_q();
        op = @(varargin)proj_spectral_svds_q( q,vectorFunction, varargin{:} );
    else
        op = @(varargin)proj_spectral_svd_q( q,vectorFunction, varargin{:} );
    end
end

function [ v, X ] = proj_spectral_svd_q( q,eproj, X, t )
sx = size( X );
SP = issparse(X);
if length( sx ) > 2,
    X = reshape( X, prod(sx(1:end-1)), sx(end) );
end
v = 0;
if nargin > 3 && t > 0,
    if SP, X = full(X); end % svd, eig, and norm require full matrices
    [U,D,V] = svd( X, 'econ' );
    [dum,D] = eproj(diag(D),q); % not q*t, since we are just projecting...
    X       = U*diag(D)*V';
    if SP, X = sparse(X); end
    X = reshape( X, sx );
else
    if SP, 
        [nrm,cnt] = normest(X,1e-3);
    else
        nrm = norm(X);
    end
    if nrm > q
        v = Inf;
    end
end

function [ v, X ] = proj_spectral_eig_q( q,eproj, X, t )
SP  = issparse(X);
v = 0;
if nargin > 3 && t > 0,
    if SP, X = full(X); end % svd, eig, and norm require full matrices
    [V,D]   = safe_eig(X); % just in case X is sparse
    [dum,D] = eproj(diag(D),q); % not q*t, since we are just projecting...
    X       = V*diag(D)*V';
    if SP, X = sparse(X); end
else
    if SP, [nrm,cnt] = normest(X,1e-3);
    else nrm = norm(X); 
    end
    if nrm > q
        v = Inf;
    end
end

% --------------- largescale functions: use eigs or svds -----------------------
function [ v, X ] = proj_spectral_eigs_q( q,eproj, X, t )
persistent oldRank
persistent nCalls
persistent V
if nargin == 0, oldRank = []; v = nCalls; nCalls = []; V=[]; return; end
if isempty(nCalls), nCalls = 0; end
SP  = issparse(X);
v = 0;
if nargin > 3 && t > 0,
    
    if isempty(oldRank), K = 10;
    else, K = oldRank + 2;
    end
    [M,N]   = size(X);
    
    ok = false;
    opts = [];
    opts.tol = 1e-10;
    if isreal(X)
        opts.issym = true;
    end
    while ~ok
        K = min( [K,M,N] );
        [V,D] = eigs( X, K, 'LM', opts );
        ok = (min(abs(diag(D))) < q) || ( K == min(M,N) );
        if ok, break; end
        K = 2*K;
        if K > 10
            opts.tol = 1e-6;
        end
        if K > 40
            opts.tol = 1e-4;
        end
        if K > 100
            opts.tol = 1e-3;
        end
        if K > min(M,N)/2
            [V,D]   = safe_eig(full((X+X')/2));
            ok = true;
        end
    end
    oldRank = length(find(abs(diag(D)) > q));
    
    [dum,D_proj] = eproj(diag(D),q);
    % we want to keep the singular vectors that we haven't discovered
    %   small = X - V*D*V'
    %   large = V*D_proj*V'
    % and add together to get X - V*(D-Dproj)*V'
    
    X       = X - V*diag(diag(D)-D_proj)*V';
    
    if SP, X = sparse(X); end
else
    if SP, [nrm,cnt] = normest(X,1e-3);
    else nrm = norm(X); 
    end
    if nrm > q
        v = Inf;
    end
end


function [ v, X ] = proj_spectral_svds_q( q,eproj, X, t )
persistent oldRank
persistent nCalls
persistent V
if nargin == 0, oldRank = []; v = nCalls; nCalls = []; V=[]; return; end
if isempty(nCalls), nCalls = 0; end
SP  = issparse(X);
v = 0;
if nargin > 3 && t > 0,
    
    if isempty(oldRank), K = 10;
    else, K = oldRank + 2;
    end
    [M,N]   = size(X);
    
    ok = false;
    opts = [];
    opts.tol = 1e-10; % the default in svds
    opt  = [];
    opt.eta = eps; % makes compute_int slow
    opt.delta = 10*opt.eta;
    while ~ok
        K = min( [K,M,N] );
        if exist('lansvd','file')
            [U,D,V] = lansvd(X,K,'L',opt );
        else
            [U,D,V] = svds(X,K,'L',opts);
        end
        ok = (min(abs(diag(D))) < q) || ( K == min(M,N) );
        if ok, break; end
        K = 2*K;
        if K > 10
            opts.tol = 1e-6;
        end
        if K > 40
            opts.tol = 1e-4;
        end
        if K > 100
            opts.tol = 1e-3;
        end
        if K > min(M,N)/2
            [U,D,V] = svd( full(X), 'econ' );
            ok = true;
        end
    end
    oldRank = length(find(abs(diag(D)) > q));
    
    [dum,D_proj] = eproj(diag(D),q);
    X       = X - U*diag(diag(D)-D_proj)*V';
    
    if SP, X = sparse(X); end
else
    if SP, [nrm,cnt] = normest(X,1e-3);
    else nrm = norm(X); 
    end
    if nrm > q
        v = Inf;
    end
end

% TFOCS v1.3 by Stephen Becker, Emmanuel Candes, and Michael Grant.
% Copyright 2013 California Institute of Technology and CVX Research.
% See the file LICENSE for full license information.

