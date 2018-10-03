function varargout = solver_sLP( c, A, b, mu, x0, z0, opts, varargin )
% SOLVER_SLP Generic linear programming in standard form. Uses smoothing.
% [ x, out, opts ] = solver_sLP( c, A, b, mu, x0, z0, opts )
%    Solves the smoothed standard form Linear Program (LP)
%        minimize c'*x + 0.5*mu*||x-x0||_2^2
%        s.t.     A * x == b and x >= 0
%    
%   "c" and "b" must be vectors, and "A" must be a matrix (dense or sparse)
%   or a function that computes A*x and A'*y (see help documentation).
%
%   If the constraint "x >= 0" is not needed, then specify this by
%       setting:
%           opts.nonnegativity = false
%
%   For maximum efficiency, the user should specify the spectral norm of A,
%       via opts.normA
%   (e.g. opts.normA = norm(A) or opts.normA = normest(A))
%
% July 13 2015, algorithm updated for x>=0 case. 
%   Uses many fewer dual variables now,
%   convergence is faster, and the primal variable is guaranteed
%   to always be non-negative.
% Also set to use non-linear CG when available

% Supply default values
error(nargchk(4,8,nargin));
if nargin < 5, x0 = []; end
if nargin < 6, z0 = []; end
if nargin < 7, opts = []; end
if ~isfield( opts, 'restart' ), opts.restart = 1000; end


% Do we include the x >= 0 constraint?
NONNEG = true;
if isfield(opts,'nonnegativity')
    if ~opts.nonnegativity
        NONNEG = false;
    end
    opts = rmfield(opts,'nonnegativity');
end


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

if exist('tfocs_CG','file') && exist('wp_ls','file') % wp_ls.m is the linesearch code for the nonliner CG
    if ~isfield(opts,'alg') || isempty(opts.alg)
        opts.alg = 'CG';
        disp('Using non-linear conjugate gradients');
    end
end

if ~NONNEG
    % There is no x >= 0 constraint:
    % Note: [] after {A,-b} is equivalent to proj_Rn
    [varargout{1:max(nargout,1)}] = ...
        tfocs_SCD( obj, { A, -b }, [], mu, x0, z0, opts, varargin{:} );
else
    % There is a x >= 0 constraint:
%     [varargout{1:max(nargout,1)}] = ...
%         tfocs_SCD( obj, { 1,0;A,-b}, {proj_Rplus,proj_Rn}, mu, x0, z0, opts, varargin{:} );
    % New, July 13 2015, exploting new prox_shift function. Much better!
    obj = prox_shift(proj_Rplus,c);
    [varargout{1:max(nargout,1)}] = ...
        tfocs_SCD( obj, { A, -b }, [], mu, x0, z0, opts, varargin{:} );
end

% TFOCS v1.3 by Stephen Becker, Emmanuel Candes, and Michael Grant.
% Copyright 2013 California Institute of Technology and CVX Research.
% See the file LICENSE for full license information.

