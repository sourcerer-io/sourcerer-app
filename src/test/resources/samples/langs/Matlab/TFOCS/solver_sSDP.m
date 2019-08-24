function varargout = solver_sSDP( c, A, b, mu, x0, z0, opts, varargin )
% SOLVER_SSDP Generic semi-definite programs (SDP). Uses smoothing.
% [ x, out, opts ] = solver_sSDP( C, A, b, mu, X0, z0, opts )
%    Solves the smoothed standard form Semi-Definite Program (SDP)
%        minimize trace(C'*X) + 0.5*mu*||X-X0||_F^2
%        s.t.     A * vec(X) == b and X >= 0
%           where X >= 0 indicates that X is positive semi-definite.
%    
%   "C" and must be a matrix, "b" must be a vector, and 
%   "A" must be a matrix (dense or sparse)
%   or a function that computes A*x and A'*y (see help documentation).
%   The operation b = A*vec(X) is equivalent to
%       b_i = trace( A_i'*X ) for i = 1:size(A,1), where A_i is the symmetric
%       matrix formed by reshaping the ith row of A.
%
%
%   For maximum efficiency, the user should specify the spectral norm of A,
%       via opts.normA
%   (e.g. opts.normA = norm(A) or opts.normA = normest(A))
%
%   By default, this assumes variables are real.
%   To allow X to be complex, either pass in a complex value for X0
%   or make sure A is complex,
%   or specify opts.cmode = 'C2R'
%       (note: cmode = 'C2C' is not supported)
%
% July 2015, improved model. Fewer dual variables, faster convergence.
% Also, use non-linear conjugate gradients if available
%
%   See also solver_sLMI

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


N = size(c,1); if N ~= size(c,2), error('"C" must be square and symmetric'); end
if ~isa(A,'function_handle')
    % We need to tell TFOCS that we'll be using matrix variables
    M = size(A,1); if size(A,2) ~= N^2, error('"A" has wrong number of columns'); end
    sz = { [N,N], [M,1] }; % specify dimensions of domain and range of A
    if isfield( opts, 'cmode' )
        cmode = opts.cmode;
    else
        if ~isempty(x0) && ~isreal(x0)
            cmode = 'C2R';
        elseif ~isreal(A) || ~isreal(c) % bug fix, Tue Apr 26, 2011
            cmode = 'C2R';  % if A is complex, then X must be, in order to get real output
        else
            cmode = 'R2R';  % default assumption
        end
    end
    vec = @(x) x(:);
    mat = @(y) reshape(y,N,N);
    A = linop_handles( sz, @(X)real(A*vec(X)), @(y) mat(A'*y),cmode);
end



% Perform the re-scaling:
A      = linop_compose( A, 1 / normA );
b      = b/normA;

if exist('tfocs_CG','file') && exist('wp_ls','file') % wp_ls.m is the linesearch code for the nonliner CG
    opts.alg = 'CG';
    disp('Using non-linear conjugate gradients');
end

% obj    = smooth_linear(c);
% [varargout{1:max(nargout,1)}] = ...
%     tfocs_SCD( obj, { 1,0;A,-b}, {proj_psd,proj_Rn}, mu, x0, z0, opts, varargin{:} );
% ind = 2;

% July 13 2015, better model (fewer dual variables)
obj     = prox_shift( proj_psd, c );
[varargout{1:max(nargout,1)}] = ...
    tfocs_SCD( obj, {A,-b}, [], mu, x0, z0, opts, varargin{:} );
ind = 1;

% and undo the scaling by normA:
if nargout >= 2 && isfield( varargout{1},'dual' ) && normA ~= 1
    if isa( varargout{2}.dual,'tfocs_tuple')
        varargout{2}.dual = tfocs_tuple( {varargout{2}.dual{1},  varargout{2}.dual{2}/normA });
    else
        varargout{2}.dual{ind} = varargout{2}.dual{ind}/normA;
    end
end

% TFOCS v1.3 by Stephen Becker, Emmanuel Candes, and Michael Grant.
% Copyright 2013 California Institute of Technology and CVX Research.
% See the file LICENSE for full license information.

