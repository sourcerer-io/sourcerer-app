function op = prox_nuclear( q, SVD_STYLE )
%PROX_NUCLEAR    Nuclear norm.
%    OP = PROX_NUCLEAR( q ) implements the nonsmooth function
%        OP(X) = q * sum(svd(X)).
%    Q is optional; if omitted, Q=1 is assumed. But if Q is supplied, 
%    it must be a positive real scalar.
%
%    OP = PROX_NUCLEAR( q, SVD_STYLE )
%       uses a Lanczos-based SVD based on PROPACK
%       if SVD_STYLE == 1 or 'propack',
%
%       or Matlab's Lanczos-based SVDS is SVD_STYLE == 2 or 'arpack'
%       (calls SVDS, which calls EIGS, which uses ARPACK)
%
%       or a randomized algorithm based on [1] if SVD_STYLE==3 or 
%       'randomized'
%
%       otherwise it uses a dense matrix SVD
%
%       (default: dense matrix SVD if X is dense and less than 300^2
%        elements, otherwise the randomized algorithm)
%
%    CALLS = PROX_NUCLEAR( 'reset' )
%       resets the internal counter and returns the number of function
%       calls
%
% [1] "Finding Structure with Randomness: Probabilistic Algorithms 
% for Constructing Approximate Matrix Decompositions"
% by N. Halko, P. G. Martinsson, and J. A. Tropp. SIAM Review vol 53 2011.
% http://epubs.siam.org/doi/abs/10.1137/090771806
%
% This implementation uses a naive approach that does not exploit any
% a priori knowledge that X and G are low rank or sparse. Future
% implementations of TFOCS will be able to handle low-rank matrices 
% more effectively.
%
% Dual: proj_spectral.m
% See also prox_trace.m  and proj_spectral.m

if nargin == 1 && strcmpi(q,'reset')
    op = prox_nuclear_impl;
    return;
end

if nargin == 0
	q = 1;
elseif ~isnumeric( q ) || ~isreal( q ) || numel( q ) ~= 1 || q <= 0
	error( 'Argument must be positive.' );
end
if nargin < 2, SVD_STYLE = []; end

% clear the persistent values:
prox_nuclear_impl();

op = @(varargin)prox_nuclear_impl( q, SVD_STYLE, varargin{:} );

end % end of main function

function [ v, X ] = prox_nuclear_impl( q, SVD_STYLE, X, t )
persistent oldRank
persistent nCalls
persistent V_save
if nargin == 0, oldRank = []; v = nCalls; nCalls = []; V_save=[]; return; end
if isempty(nCalls), nCalls = 0; end

ND = (size(X,2) == 1);
% ND = ~ismatrix(X);
if ND % X is a vector, not a matrix, so reshape it 
    sx = size(X);
    X = reshape( X, prod(sx(1:end-1)), sx(end) );
end

% Determine which SVD we will use:
% 0 = dense
% 1 = PROPACK
% 2 = ARPACK
% 3 = Randomized
if isempty(SVD_STYLE)
    % use a default
    if numel(X) > 300^2 || issparse(X)
        SVD_STYLE = 'randomized';
    else
        SVD_STYLE = 'dense';
    end
end
SVD_STYLE = lower(SVD_STYLE);
switch SVD_STYLE
    case {1,'propack'}
        if ~exist('lansvd','file')
            warning(...
                'TFOCS:prox_nuclear',...
                'Cannot find lansvd.m, required by PROPACK; using default SVD_type');
            SVD_STYLE = 'arpack';
        end
    case {3,'randomized'}
        if ~exist('randomizedSVD','file')
            warning(...
                'TFOCS:prox_nuclear',...
                'Cannot find randomizedSVD.m, required by SVD_TYPE; using default SVD_type');
            SVD_STYLE = 'arpack';
        end
end

opts = struct('tol',1e-10); % 1e-10 is default in svds
% Define [U,S,V] = svdFcn( X, K, opt )
switch SVD_STYLE
    case {1,'propack'}
        % These fields are used by lansvd, otherwise are ignored
        opts.eta = eps; % makes compute_int slow
        %opt.eta = 0;  % makes reorth slow
        opts.delta = 10*opts.eta;
        svdFcn = @(X,K,opt) lansvd( X, K, 'L', opt ); % fixed bug, 3/29/15
    case {2,'arpack'}
        svdFcn = @(X,K,opt) svds(X,K,'L',opt);
    case {3,'randomized'}
        nPower      = 2; % 2 or 3 is good
        overSample  = 20;
        warning('off','randomizedSVD:warmStartLarge');
        svdFcn = @(X,K,opt) randomizedSVD( X, K, K+overSample, nPower, [], struct( 'warmStart', V_save ) );
end

if nargin > 3 && t > 0
    
    tau = q*t;
    nCalls = nCalls + 1;
    
    if isequal(SVD_STYLE,0) || strcmpi(SVD_STYLE,'dense')
        [U,S,V] = svd( full(X), 'econ' );
    else
        % Guess which singular value will have value near tau:
        [M,N] = size(X);
        if isempty(oldRank), K = 10;
        else K = oldRank + 2;
        end
        
        ok = false;

        while ~ok
            K = min( [K,M,N] );
            [U,S,V] = svdFcn(X,K,opts );
            ok = (min(diag(S)) < tau) || ( K == min(M,N) );
            if ok, break; end
%             K = K + 5;
            K = 2*K;
            if K > 10
                opts.tol = 1e-6;
            end
            if K > 40
                opts.tol = 1e-4;
            end
            if K > 100
                opts.tol = 1e-1;
            end
            if K > min(M,N)/2
                [U,S,V] = svd( full(X), 'econ' );
                ok = true;
            end
        end
        oldRank = length(find(diag(S) > tau));
    end
    s  = diag(S) - tau;
    tt = s > 0;
    s  = s(tt,:);

    if isempty(s)
        X = tfocs_zeros(X);
    else
        X = U(:,tt) * bsxfun( @times, s, V(:,tt)' );
    end
    switch SVD_STYLE
        case {3,'randomized'}
            V_save  = V;
    end
else
    s = svd(full(X)); % could be expensive!
end

v = q * sum(s);
if ND
    X = reshape( X, sx ); 
end

end


% TFOCS v1.3 by Stephen Becker, Emmanuel Candes, and Michael Grant.
% Copyright 2013 California Institute of Technology and CVX Research.
% See the file LICENSE for full license information.
