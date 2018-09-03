function varargout = solver_sBPDN_W( A, W, b, epsilon, mu, x0, z0, opts, varargin )
% SOLVER_SBPDN_W Weighted BPDN problem. Uses smoothing.
% [ x, out, opts ] = solver_sBPDN_W( A, W, b, epsilon, mu, x0, z0, opts )
%    Solves the smoothed basis pursuit denoising problem
%        minimize norm(Wx,1) + 0.5*mu*(x-x0).^2
%        s.t.     norm(A*x-b,2) <= epsilon
%    by constructing and solving the composite dual.
%    A and W must be a linear operator or matrix, and b must be a vector. The
%    initial point x0 and the options structure opts are optional.
%
%    If "nonneg" is a field in "opts" and opts.nonneg is true,
%       then the constraints are     norm(A*x-b,2) <= epsilon   AND  x >= 0
%    If "box" is a field in "opts" and opts.box = [l,u]
%       then the constraints are    norm(A*x-b,2) <= epsilon   AND  l <= x <= u
%
%    See also solver_sBPDN


% Supply default values
error(nargchk(5,9,nargin));
if nargin < 6, x0 = []; end
if nargin < 7, z0 = []; end
if nargin < 8, opts = []; end
if ~isfield( opts, 'restart' ), opts.restart = 1000; end

if epsilon < 0
    error('TFOCS error: epsilon is negative');
end
% we don't have solver_sBP_W, so am building this into this function:
%if ~epsilon
    %error('TFOCS error: cannot handle epsilon = 0.  Please call solver_sBP_W instead');
%elseif epsilon < 100*builtin('eps')
    %warning('TFOCS:badConstraint',...
        %'TFOCS warning: epsilon is near zero; consider calling solver_sBP instead');
%end

% Need to estimate the norms of A*A' and W*W' in order to be most efficient
if isfield( opts, 'noscale' ) && opts.noscale,
    normA2 = 1; normW2 = 1;
else
    normA2 = []; normW2 = [];
    if isfield( opts, 'normA2' ),
        normA2 = opts.normA2;
        opts = rmfield( opts, 'normA2' );
    end
    if isfield( opts, 'normW2'  ),
        normW2 = opts.normW2;
        opts = rmfield( opts, 'normW2' );
    end
end
if isempty( normA2 ),
    normA2 = linop_normest( A ).^2;
end
if isempty( normW2 ),
    normW2 = linop_normest( W ).^2;
end

% if ~isfield(opts,'L0') || isempty(opts.L0)
%     opts.L0 = normA2/mu;  % is this right? check
% end

proxScale   = sqrt( normW2 / normA2 );
if epsilon > 0
    prox        = { prox_l2( epsilon ), proj_linf(proxScale) };
else
    prox        = { proj_Rn, proj_linf(proxScale) };
end
W           = linop_compose( W, 1 / proxScale );

% Adding Jan 2014
nonneg = false; box = false;
if isfield(opts,'nonneg')
    nonneg  = opts.nonneg;
    opts = rmfield(opts,'nonneg');
end
if isfield(opts,'nonNeg')
    nonneg  = opts.nonNeg;
    opts = rmfield(opts,'nonNeg');
end
if nonneg       
    % -- case: x >= 0 constraints
    proxP    = proj_Rplus;
else
    % -- case: no x >= 0 constraint
    proxP    = [];
end
if isfield(opts,'box')
    box  = opts.box;
    if length(box)==2
        if nonneg, error('cannot use box constaints and non-neg constraints simultaneously');
        end
        proxP   = proj_box(box(1),box(2));
    end
    opts = rmfield(opts,'box');
end


[varargout{1:max(nargout,1)}] = ...
    tfocs_SCD( proxP, { A, -b; W, 0 }, prox, mu, x0, z0, opts, varargin{:} );

% TFOCS v1.3 by Stephen Becker, Emmanuel Candes, and Michael Grant.
% Copyright 2013 California Institute of Technology and CVX Research.
% See the file LICENSE for full license information.

