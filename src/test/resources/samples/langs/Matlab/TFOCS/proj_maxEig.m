function op = proj_maxEig( q, LARGESCALE )

%PROJ_MAXEIG Projection onto the set of matrices with max eigenvalue less than or equal to q
%    OP = PROJ_MAXEIG( q ) returns a function that implements the
%    indicator for matrices with spectral norm less than q.
%    Q is optional; if omitted, Q=1 is assumed. But if Q is supplied, 
%    it must be a positive real scalar.
%    This function is similar proj_spectral.m but assumes that
%    the input is real symmetric. For positive semi-definite inputs,
%    this function is equivalent to proj_spectral
%   OP = PROJ_MAXEIG( ..., largescale) will switch to using
%    eigs instead of svd or eig, if largescale==true. This is usually
%    beneficial for large, sparse variables.
%
% Dual: prox_trace(q)
%   (if domain is pos. semidefinite matrices, then prox_trace(q)
%    is also the dual, and is more efficient than prox_nuclear(q) ).
%
% See also prox_trace, prox_nuclear, proj_spectral, prox_spectral

% Sept 1, 2012
if nargin < 2 || isempty(LARGESCALE)
    LARGESCALE  = false;
end

if nargin == 0,
	q = 1;
elseif ~isnumeric( q ) || ~isreal( q ) || numel( q ) ~= 1 || q <= 0,
	error( 'Argument must be positive.' );
end
% vectorFunction = proj_linf( q ); % for proj_spectral.m
vectorFunction = proj_max( q ); 

if LARGESCALE
    % clear the persistent values:
    proj_maxEig_eigs_q();
    op = @(varargin)proj_maxEig_eigs_q( q,vectorFunction, varargin{:} );
else
    op = @(varargin)proj_maxEig_eig_q( q,vectorFunction, varargin{:} );
end


function [ v, X ] = proj_maxEig_eig_q( q,eproj, X, t )
SP  = issparse(X);
v = 0;
if nargin > 3 && t > 0,
    if SP, X = full(X); end % svd, eig, and norm require full matrices
    [V,D]   = safe_eig(X); % just in case X is sparse
    [dum,D] = eproj(diag(D),q); % not q*t, since we are just projecting...
    X       = V*diag(D)*V';
    if SP, X = sparse(X); end
else
    nrm = max(eig(X));
    if nrm > q
        v = Inf;
    end
end

% --------------- largescale functions: use eigs or svds -----------------------
function [ v, X ] = proj_maxEig_eigs_q( q,eproj, X, t )
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
        SIGMA   = 'LA'; % not 'LM' like proj_spectral
    else
        SIGMA   = 'LR';
    end
    while ~ok
        K = min( [K,M,N] );
        if K > min(M,N)/2 || K > (min(M,N)-2) || min(M,N) < 20
            [V,D]   = safe_eig(full((X+X')/2));
            ok = true;
        else
            [V,D] = eigs( X, K, SIGMA, opts );
            ok = (min(abs(diag(D))) < q) || ( K == min(M,N) );
        end
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
    end
    oldRank = length(find(diag(D) > q)); % no abs here
    
    [dum,D_proj] = eproj(diag(D),q);
    % we want to keep the singular vectors that we haven't discovered
    %   small = X - V*D*V'
    %   large = V*D_proj*V'
    % and add together to get X - V*(D-Dproj)*V'
    
    X       = X - V*diag(diag(D)-D_proj)*V';
    
    if SP, X = sparse(X); end
else
%     if SP
        opts = struct('tol',1e-8);
        if isreal(X)
            opts.issym = true;
            SIGMA   = 'LA'; % not 'LM' like proj_spectral
        else
            SIGMA   = 'LR';
        end
        K = 1;
        D = eigs( X, K, SIGMA , opts );
        nrm = max(D);
%     else
%         nrm = max(eig(X));
%     end
    if nrm > q
        v = Inf;
    end
end



% TFOCS v1.3 by Stephen Becker, Emmanuel Candes, and Michael Grant.
% Copyright 2013 California Institute of Technology and CVX Research.
% See the file LICENSE for full license information.

