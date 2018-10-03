function varargout = solver_sLP_box( c, A, b, l, u, mu, x0, z0, opts, varargin )
% SOLVER_SLP_BOX Generic linear programming with box constraints. Uses smoothing.
% [ x, out, opts ] = solver_sLP_box( c, A, b, l, u, mu, x0, z0, opts )
%    Solves the smoothed standard form Linear Program (LP) with box-constraints
%        minimize c'*x + 0.5*mu*||x-x0||_2^2
%        s.t.     A * x == b and  l <= x <= b
%    
%   "c" and "b" must be vectors, and "A" must be a matrix (dense or sparse)
%   or a function that computes A*x and A'*y (see help documentation).
%   "l" and "u" are vectors, or scalars (in which case they are a scalar
%    times the vector of all ones )
%
%   If only "l" (or only "u") is needed, set "u" (or "l") to the empty matrix [].
%
%   For maximum efficiency, the user should specify the spectral norm of A,
%       via opts.normA
%   (e.g. opts.normA = norm(A) or opts.normA = normest(A))
%
% July 13, 2015, algorithmic change to improve the performance.
% Also set to use non-linear CG when available
%
%   See also solver_sLP

% Supply default values
error(nargchk(6,10,nargin));
if nargin < 7, x0 = []; end
if nargin < 8, z0 = []; end
if nargin < 9, opts = []; end
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

% Perform the re-scaling:
if isnumeric(A), A = A/normA; % do it once
else
A      = linop_compose( A, 1 / normA );
end
b      = b/normA;


obj    = smooth_linear(c);

if exist('tfocs_CG','file')&& exist('wp_ls','file') % wp_ls.m is the linesearch code for the nonliner CG
    opts.alg = 'CG';
    disp('Using non-linear conjugate gradients');
end

if isempty(l) && isempty(u)
    % There is no x >= 0 constraint:
    [varargout{1:max(nargout,1)}] = ...
        tfocs_SCD( obj, { A, -b }, [], mu, x0, z0, opts, varargin{:} );
else
    % added Juy 13, 2015
    % This has fewer dual variables and should be much better!
    obj = prox_shift( proj_box(l,u), c );
    
    [varargout{1:max(nargout,1)}] = ...
        tfocs_SCD( obj, { A, -b }, [], mu, x0, z0, opts, varargin{:} );
    
% elseif isempty(u)
%     % There is a x >= l constraint, i.e. x - l >= 0
%     [varargout{1:max(nargout,1)}] = ...
%         tfocs_SCD( obj, { 1,-l;A,-b}, {proj_Rplus,proj_Rn}, mu, x0, z0, opts, varargin{:} );
% elseif isempty(l)
%     % There is a x <= u constraint, i.e. -x + u >= 0
%     [varargout{1:max(nargout,1)}] = ...
%         tfocs_SCD( obj, {-1, u;A,-b}, {proj_Rplus,proj_Rn}, mu, x0, z0, opts, varargin{:} );
% else
%     % have both upper and lower box constraints
%     [varargout{1:max(nargout,1)}] = ...
%         tfocs_SCD( obj, {1,-l;-1, u;A,-b}, {proj_Rplus,proj_Rplus,proj_Rn}, mu, x0, z0, opts, varargin{:} );
end

% TFOCS v1.3 by Stephen Becker, Emmanuel Candes, and Michael Grant.
% Copyright 2013 California Institute of Technology and CVX Research.
% See the file LICENSE for full license information.

