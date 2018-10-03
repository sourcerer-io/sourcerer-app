function op = prox_trace( q, LARGESCALE, isReal )

%PROX_TRACE     Nuclear norm, for positive semidefinite matrices. Equivalent to trace.
%    OP = PROX_TRACE( q ) implements the nonsmooth function
%        OP(X) = q * sum(svd(X)) = q*tr(X) ( X >= 0 assumed )
%    Q is optional; if omitted, Q=1 is assumed. But if Q is supplied, 
%    it must be a positive real scalar (the positivity is not necessary mathematically,
%       so if you want q<0, set SIGMA=q*eye(n); see below )
%    This function is a combination of the proximity function of the trace
%    and projection onto the set of symmetric/Hermitian matrices.
%
%    OP = PROX_TRACE( SIGMA ) represents the function
%       OP(X) = trace( SIGMA * X ), such that X >= 0
%       Here, SIGMA should be a symmetric (or Hermitian) matrix, but need not
%       be positive semidefinite
%
%    OP = PROX_TRACE( q/SIGMA, LARGESCALE )
%       uses a Lanczos-based Eigenvalue decomposition if LARGESCALE == true,
%       otherwise it uses a dense matrix Eigenvalue decomposition
%
%    OP = PROX_TRACE( q/SIGMA, LARGESCALE, isReal )
%       also projects onto the set of real matrices if isReal=true.
%
%    CALLS = PROX_TRACE( 'reset' )
%       resets the internal counter and returns the number of function
%       calls
%
% This implementation uses a naive approach that does not exploit any
% a priori knowledge that X and G may be low rank (plus sparse). Future
% implementations of TFOCS will be able to handle low-rank matrices 
% more effectively.
% Dual: proj_spectral(q,'symm')
% See also proj_spectral, prox_nuclear, proj_psdUTrace

% April 4 2014, adding support for nonscalar q, i.e., q=SIGMA

if nargin == 1 && strcmpi(q,'reset')
    op = prox_trace_impl;
    return;
end

if nargin == 0,
	q = 1;
elseif ~isnumeric( q ) || ~isreal( q ) %|| numel( q ) ~= 1 || q <= 0,
	error( 'Argument must be positive.' );
elseif numel(q) ==1 && q<= 0
    error('For now, argument must be positive. If you need negative, make q=-eye(n)');
    % April 4, realized that since this is just linear, we do not need to restrict
    %   q to be positive.
elseif numel(q) >1 && norm(q-q','fro')/norm(q,'fro') > 1e-5
    error('When q is a matrix, it must be symmetric/Hermitian');
end
if nargin < 2, LARGESCALE = []; end
if nargin < 3 || isempty(isReal), isReal = false; end

% clear the persistent values:
prox_trace_impl();

op = @(varargin)prox_trace_impl( q, LARGESCALE, isReal, varargin{:} );
end

function [ v, X ] = prox_trace_impl( q,LARGESCALE, isReal, X, t )
persistent oldRank
persistent nCalls
persistent V
if nargin == 0, oldRank = []; v = nCalls; nCalls = []; V=[]; return; end
if isempty(nCalls), nCalls = 0; end

if nargin >= 5 && t > 0,
    
    if ~isempty(LARGESCALE) 
        largescale = LARGESCALE;
    else
        largescale = ( numel(X) > 100^2 ) && issparse(X);
    end
    if numel(q)==1
        tau = q*t;
    else
        % q is really a matrix Sigma
        % We can absorb this easily
        X   = X - t*q;
        tau = 0;
    end
    nCalls = nCalls + 1;
    
    if ~largescale
        if isReal
            % July 10 2015, adding try-catch statement
            % to deal with bug in eig() sometimes
            [V,D]   = safe_eig(real(full((X+X')/2)));
        else
            [V,D]   = safe_eig(full((X+X')/2));
        end
    else

        % Guess which eigenvalue value will have value near tau:
        [M,N] = size(X);
        X = (X+X')/2;
        if isReal, X = real(X); end
        if isempty(oldRank), K = 10;
        else, K = oldRank + 2;
        end
        
        ok = false;
        opts = [];
        opts.tol = 1e-10; 
        if isreal(X)
            opts.issym  = true;
            SIGMA       = 'LA';
        else
            SIGMA       = 'LR';
        end
        % SIMGA = 'LM' (bug) prior to March 18 2012
        while ~ok
            K = min( [K,M,N] );
            
            if K > min(M,N)/2
                [V,D]   = safe_eig(full((X+X')/2));
                ok = true;
                break;
            end
            
            [V,D] = eigs( X, K, SIGMA, opts );
            ok = (min(diag(D)) < tau) || ( K == min(M,N) );
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
        oldRank = length(find(diag(D) > tau));
    end
    s  = diag(D) - tau;
    tt = s > 0;
    s  = s(tt,:);
    
    if isempty(s),
        X = tfocs_zeros(X);
    else
        X = V(:,tt) * bsxfun( @times, s, V(:,tt)' );
        % And force it to be symmetric
        X = (X+X')/2;
    end
    if numel(q)==1
        v = q * sum(s);
    else
        % This is what we compute
        %v   = tr( q'*X );
        % but here is a faster way:
        v   = q(:)'*X(:);
    end
else
    if numel(q)==1
        v = q* trace( X + X' )/2;
    else
        X = (X+X')/2;
        v   = q(:)'*X(:);
    end
end

end


% TFOCS v1.3 by Stephen Becker, Emmanuel Candes, and Michael Grant.
% Copyright 2013 California Institute of Technology and CVX Research.
% See the file LICENSE for full license information.
