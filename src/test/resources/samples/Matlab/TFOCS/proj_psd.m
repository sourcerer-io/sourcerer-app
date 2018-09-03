function op = proj_psd( LARGESCALE, isReal, K )

% PROJ_PSD  Projection onto the positive semidefinite cone.
%   OP = PROJ_PSD() returns a function that implements
%   the projection onto the semidefinite cone:
%	X = argmin_{min(eig(X))>=0} norm(X-Y,'fro')
%
%   OP = PROJ_PSD( LARGESCALE )
%     performs the same computation, but in a more efficient
%     manner for the case of sparse (and low-rank) matrices
%
%   OP = PROJ_PSD( LARGESCALE, isReal )
%     also includes the constraint that X is real-valued if isReal is true.
%
% This function is self-dual.
% See also proj_Rplus.m, the vector analog of this function

% in the future, we might include this nonconvex version:
%   OP = PROJ_PSD( LARGESCALE, isReal, k )
%     only returns at most a rank k matrix
%

if nargin == 0 || isempty(LARGESCALE), LARGESCALE = false; end
if nargin < 2 || isempty(isReal), isReal = false; end
if nargin < 3,  K = Inf;  end

if ~LARGESCALE
    op = @(varargin)proj_psd_impl(isReal, varargin{:} );
else
    proj_psd_largescale();  % reset any counters
    op = @(varargin)proj_psd_largescale( K, isReal, varargin{:} );
end


function [ v, X ] = proj_psd_impl( isReal, X, t )
if nargin > 2 && t > 0,
	v = 0;
    X = full(X+X'); % divide by 2 later
    if isReal, X = real(X); end
    [V,D]=safe_eig(X); % we don't yet take advantage of sparsity here
    D  = max(0.5*diag(D),0);
    tt = D > 0;
    V  = bsxfun(@times,V(:,tt),sqrt(D(tt,:))');
    X  = V * V';
else
    s = eig(full(X+X'))/2;
    if min(s) < -8*eps*max(s),
        v = Inf;
    else
    	v = 0;
   	end
end


function [ v, X ] = proj_psd_largescale(Kignore,isReal, X, t )
% Updated Sept 2012. The restriction to rank K "Kignore" has not been done yet
% (that is nonconvex)
persistent oldRank
persistent nCalls
persistent V
if nargin == 0, oldRank = []; v = nCalls; nCalls = []; V=[]; return; end
if isempty(nCalls), nCalls = 0; end
SP  = issparse(X);

if nargin > 3 && t > 0,
	v = 0;
    if isempty(oldRank), K = 10;
    else, K = oldRank + 2;
    end

    [M,N]   = size(X);
    EIG_TOL         = 1e-10;
    ok = false;
    opts = [];
    opts.tol = 1e-10;
    if isreal(X)
        opts.issym = true;
        SIGMA       = 'LA';
    else
        SIGMA       = 'LR'; % largest real part
    end
    X = (X+X')/2;
    if isReal, X = real(X); end
    while ~ok
        K = min( [K,N] );
        if K > N/2 || K > N-2 || N < 20
            [V,D]   = safe_eig(full((X+X')/2));
            ok = true;
        else
            [V,D] = eigs( X, K, SIGMA, opts );
            ok = (min(real(diag(D))) < EIG_TOL) || ( K == N );
        end
        if ok, break; end
%         opts.v0     = V(:,1); % starting vector
        K = 2*K;
%         fprintf('Increasing K from %d to %d\n', K/2,K );
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
    D   = real( diag(D) );
    oldRank = length(find( D > EIG_TOL ));

    tt = D > EIG_TOL;
    V  = bsxfun(@times,V(:,tt),sqrt(D(tt,:))');
    X  = V * V';
    if SP, X = sparse(X); end
else
    opts.tol = 1e-10;
    if isreal(X)
        opts.issym = true;
        SIGMA       = 'SA';
    else
        SIGMA       = 'SR'; % smallest real part
    end
    K = 1; % we only want the smallest
    X = full(X+X'); % divide by 2 later
    if isReal, X = real(X); end
    d = eigs(X, K, SIGMA, opts );
    d = real(d)/2;
    
    if d < -10*eps
        v = Inf;
    else
    	v = 0;
    end
end

% TFOCS v1.3 by Stephen Becker, Emmanuel Candes, and Michael Grant.
% Copyright 2013 California Institute of Technology and CVX Research.
% See the file LICENSE for full license information.

