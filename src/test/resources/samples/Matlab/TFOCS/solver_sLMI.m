function varargout = solver_sLMI( A0, A, b, mu, x0, z0, opts, varargin )
% SOLVER_SLMI Generic linear matrix inequality problems (LMI is the dual of a SDP). Uses smoothing.
% [ y, out, opts ] = solver_sLMI( A0, A, b, mu, y0, z0, opts )
%    Solves the smoothed Linear-Matrix Inequality (LMI) problem
%
%        minimize_y   b'*y
%        s.t.     A0 + sum_i A_i y(i) >= 0
%          " >= 0 " indicates that a matrix is positive semi-definite.
%    
%   "A0" and must be a symmetric/Hermitian matrix, "b" must be a vector, and 
%   "A" must be a matrix (dense or sparse)
%       with the convention that each row of A stores the vectorized symmetric/Hermitian
%       matrix A_i, so that sum_i A_i y(i) can be written as mat(A'*y)
%       (where mat() reshapes a vector into a square matrix)
%   if "A" is a function, then in forward mode it should compute A'*y
%       and in transpose mode it should compute A*X
%
%   Note: A0 and A_i must be symmetric/Hermitian, but this function
%       does not check for it, so the user must check.  If you get
%       unexpected errors, this may be the culprit.
%
%   For maximum efficiency, the user should specify the spectral norm of A,
%       via opts.normA
%   (e.g. opts.normA = norm(A) or opts.normA = normest(A))
%
%   By default, this assumes variables are real.
%   To allow y to be complex, either pass in a complex value for y0
%   or make sure A or A0 is complex,
%   or specify opts.cmode = 'R2C'
%       (note: cmode = 'C2C' is not supported)
%
%   See also solver_sSDP

% Supply default values
error(nargchk(4,8,nargin));
if nargin < 5, x0 = []; end
if nargin < 6, z0 = []; end
if nargin < 7, opts = []; end
if ~isfield( opts, 'restart' ), opts.restart = 1000; end

% Do we automatically re-scale "A"?
% (there are two dual variables, one corresponding to Ax==b
%  and one corresponding to I*x >= 0, and the dual problem
%  is most efficient if  norm(I) = norm(A),
%  hence we rescale A <-- A/norm(A)   )
if isfield( opts, 'noscale' ) && opts.noscale
    % The user has forced us not to automatically rescale
    normA = 1;
else
    normA = []; 
    if isfield( opts, 'normA' ),
        normA = opts.normA;
        opts = rmfield( opts, 'normA' );
    end
end
if isempty( normA ),
    normA = linop_normest( A );
end
if isfield( opts, 'noscale' )
    opts = rmfield(opts,'noscale');
end


N = size(A0,1); if N ~= size(A0,2), error('"A0" must be square and symmetric'); end
if ~isa(A,'function_handle')
    % We need to tell TFOCS that we'll be using matrix variables
    M = size(A,1); if size(A,2) ~= N^2, error('"A" has wrong number of columns'); end
    sz = { [M,1], [N,N] }; % specify dimensions of domain and range of A
    if isfield( opts, 'cmode' )
        cmode = opts.cmode;
    else
        if ~isempty(x0) && ~isreal(x0)
            cmode = 'R2C';
        elseif ~isreal(A) || ~isreal(A0)
            cmode = 'R2C';  % if A is complex, then X must be, in order to get real output
        else
            cmode = 'R2R';  % default assumption
        end
    end
    vec = @(x) x(:);
    mat = @(y) reshape(y,N,N);
    A = linop_handles( sz, @(y) mat(A'*y), @(X)real(A*vec(X)), cmode);
end



% Perform the re-scaling:
A      = linop_compose( A, 1 / normA );
A0     = A0/normA;


obj    = smooth_linear(b);

[varargout{1:max(nargout,1)}] = ...
    tfocs_SCD( obj, {A,A0}, {proj_psd}, mu, x0, z0, opts, varargin{:} );


% TFOCS v1.3 by Stephen Becker, Emmanuel Candes, and Michael Grant.
% Copyright 2013 California Institute of Technology and CVX Research.
% See the file LICENSE for full license information.

