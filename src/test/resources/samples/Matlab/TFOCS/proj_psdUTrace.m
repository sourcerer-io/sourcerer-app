function op = proj_psdUTrace( q, LARGESCALE, force_real, maxK, Sigma )

%PROJ_PSDUTRACE Projection onto the positive semidefinite cone with fixed trace.
%    OP = PROJ_PSDUTRACE( q ) returns a function that implements the
%    indicator for the cone of positive semidefinite (PSD) matrices with
%    fixed trace: { X | min(eig(X+X'))>=0, trace(0.5*(X+X'))<=q
%    Q is optional; if omitted, Q=1 is assumed. But if Q is supplied, 
%    it must be a positive real scalar. 
%
%    OP = PROJ_PSDUTRACE( q, LARGESCALE) will use a Lanczos-based Eigenvalue
%          decomposition if LARGESCALE==true, eitherwise it uses a dense
%          matrix decomposition
%
%    OP = PROJ_PSDUTRACE( q, LARGESCALE, forceReal ) will also include the 
%         constraint that X is a real matrix if forceReal is true.
%
%    OP = PROJ_PSDUTRACE( q, LARGESCALE, forceReal, maxK ) will only
%         use the Lanczos-solver if it expects fewer than maxK eigenvalues
%
%    OP = PROJ_PSDUTRACE( q, LARGESCALE, forceReal, maxK, Sigma ) 
%         offsets the objective function by trace(Sigma'*X), that is,
%         the overall function is trace(Sigma'*X) s.t. X >= 0, tr(X)==q
%
%    CALLS = PROJ_PSDUTRACE( 'reset' )
%         resets the internal counter and returns the number of function calls
%
% This version uses a dense eigenvalue decomposition; future versions
% of TFOCS will take advantage of low-rank and/or sparse structure.
%
% If the input to the operator is a vector of size n^2 x 1, it will
% be automatically reshaped to a n x n matrix. In this case,
% the output will also be of length n^2 x 1 and not n x n.
%
% Note: proj_simplex.m (the vector-analog of this function)
% Duals: the dual function is prox_maxEig, which also requires
%   PSD inputs. The function prox_spectral(q,'sym') is also equivalent
%   to prox_maxEig if given a PSD input.
% See also prox_maxEig, prox_spectral, proj_simplex, prox_trace

% Feb 15 2013, adding support for eigs calculations
% Apr 14 2014, adding support for the offset Sigma


if nargin == 1 && strcmpi(q,'reset')
    op = prox_trace_impl;
    return;
end

if nargin == 0,
	q = 1;
elseif ~isnumeric( q ) || ~isreal( q ) || numel( q ) ~= 1 || q <= 0,
	error( 'Argument must be positive.' );
end
if nargin < 2, LARGESCALE = []; end
if nargin < 3
    force_real = false;
end
if nargin < 4 || isempty(maxK)
    maxK    = 100;
end
if nargin < 5 
    Sigma = [];
end
if ~isempty( LARGESCALE ) && LARGESCALE
    op = @(varargin)proj_psdUTrace_q_eigs( q, maxK, force_real, Sigma, varargin{:} );
else
    op = @(varargin)proj_psdUTrace_q( q, force_real, Sigma, varargin{:} );
end

function [ v, X ] = proj_psdUTrace_q_eigs( lambda, maxK, force_real, Sigma, X, t )
persistent oldRank
persistent nCalls
persistent V
if nargin == 0, oldRank = []; v = nCalls; nCalls = []; V=[]; return; end
if isempty(nCalls), nCalls = 0; end
if isempty(maxK), maxK = size(X,1); end
if isempty(force_real), force_real = false; end

VECTORIZE   = false;
if size(X,1) ~= size(X,2)
    %error('proj_psdUTrace requires a square matrix as input');
    n = sqrt(length(X));
    X = reshape(X, n, n );
    VECTORIZE   = true;
end
v = 0;
if ~isempty(Sigma) % added April 14 2014
    X = X - t*Sigma;
end
X = full(0.5*(X+X')); % added 'full' Sept 5 2012
if force_real % added Nov 23 2012
    X = real(X);
else
    is_real     = isreal(X);
end
if nargin > 5 && t > 0
    
    opts = [];
    opts.tol = 1e-10;
    if force_real || is_real
        opts.issym = true; 
        SIGMA       = 'LA'; % get largest eigenvalues (NOT in magnitude)
    else
        SIGMA       = 'LR'; % should be real anyhow (to 1e-10). get largest real part
    end
    if isempty(oldRank), K = 10;
    else, K = oldRank + 2;
    end
    N  = size(X,1);
    ok = false;
    ctr = 0;
    FEASIBLE = false;
    while ~ok
        ctr   = ctr + 1;
        K     = min( K, N );
        if K > N/2 || K > maxK
            [V,D] = safe_eig(X); ok = true;
            D     = diag(D);
            break;
        end
%         opts.tol = min(max(opts.tol,1e-10),1e-7);

        [V,D] = eigs( X, K,SIGMA, opts );
        D     = diag(D);
        delta = ( sum(D) - lambda ) / K;
        ok    = min(D) < delta;
        
        if ok, break; end
        
        % Can we do an early return? maybe we are already feasible
        if sum(D) + (N-K-1)*min(D) < lambda
%             disp('Point is feasible! exiting');
            FEASIBLE = true;
            break;
        end
        
        % otherwise, increase K
        
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
    if FEASIBLE
        oldRank = N;
    else
        smplx   = proj_simplex(lambda);
        [dum,D] = smplx(D,1);
        spprt   = find(D);
        D = diag(D(spprt));
        V = V(:,spprt);
        X = V*D*V';
        oldRank     = length(spprt);
    end
    

    nCalls = nCalls + 1;
    if ~isempty(Sigma)
        v = Sigma(:)'*X(:);
    end
    if VECTORIZE, X = X(:); end
elseif any(eig(X)<0) || trace(X) > lambda
    v = Inf;
end



function [ v, X ] = proj_psdUTrace_q( lambda, force_real, Sigma, X, t )
persistent nCalls
if nargin == 0, v = nCalls; nCalls = []; return; end
if isempty(nCalls), nCalls = 0; end

eproj = proj_simplex( lambda );

VECTORIZE   = false;
if size(X,1) ~= size(X,2)
    %error('proj_psdUTrace requires a square matrix as input');
    n = sqrt(length(X));
    X = reshape(X, n, n );
    VECTORIZE   = true;
end
v = 0;
if ~isempty(Sigma) % added April 14 2014
    X = X - t*Sigma;
end
X = full(0.5*(X+X')); % added 'full' Sept 5 2012
if force_real % added Nov 23 2012
    X = real(X);
end
if nargin > 4 && t > 0,
    nCalls = nCalls + 1;
    [V,D]=safe_eig(X);
    [dum,D] = eproj(diag(D),t);
    tt = D > 0;
    V  = bsxfun(@times,V(:,tt),sqrt(D(tt,:))');
    X  = V * V';
    if ~isempty(Sigma)
        v = Sigma(:)'*X(:);
    end
    if VECTORIZE, X = X(:); end
elseif any(eig(X)<0) || trace(X) > lambda
    v = Inf;
end

% TFOCS v1.3 by Stephen Becker, Emmanuel Candes, and Michael Grant.
% Copyright 2013 California Institute of Technology and CVX Research.
% See the file LICENSE for full license information.

