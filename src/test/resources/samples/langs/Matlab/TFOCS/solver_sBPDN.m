function varargout = solver_sBPDN( A, b, epsilon, mu, x0, z0, opts, varargin )
% SOLVER_SBPDN Basis pursuit de-noising. BP with relaxed constraints. Uses smoothing.
% [ x, out, opts ] = solver_sBPDN( A, b, epsilon, mu, x0, z0, opts )
%    Solves the smoothed basis pursuit denoising problem
%        minimize norm(x,1) + 0.5*mu*(x-x0).^2
%        s.t.     norm(A*x-b,2) <= epsilon
%    by constructing and solving the composite dual
%        maximize - g_sm(z) - epsilon*norm(z,2)
%    where
%        gsm(z) = sup_x <z,Ax-b>-norm(x,1)-(1/2)*mu*norm(x-x0)
%    A must be a linear operator or matrix, and b must be a vector. The
%    initial point x0 and the options structure opts are optional.
%
%    If "nonneg" is a field in "opts" and opts.nonneg is true,
%       then the constraints are     norm(A*x-b,2) <= epsilon   AND  x >= 0

% Supply default values
error(nargchk(4,8,nargin));
if nargin < 5, x0 = []; end
if nargin < 6, z0 = []; end
if nargin < 7, opts = []; end
if ~isfield( opts, 'restart' ), opts.restart = 400; end

if epsilon < 0
    error('TFOCS error: epsilon is negative');
end
if ~epsilon
    error('TFOCS error: cannot handle epsilon = 0.  Please call solver_sBP instead');
elseif epsilon < 100*builtin('eps')
    warning('TFOCS:badConstraint',...
        'TFOCS warning: epsilon is near zero; consider calling solver_sBP instead');
end


% -- legacy options from original software --
if isfield(opts,'lambda0')
    opts = rmfield(opts,'lambda0');
end
if isfield(opts,'xPlug')
    opts = rmfield(opts,'xPlug');
end
if isfield(opts,'solver')
    svr     = opts.solver;
    opts    = rmfield(opts,'solver');
    if isfield(opts,'alg') && ~isempty(opts.alg)
        disp('Warning: conflictiong options for the algorithm');
    else
        % if specified as "solver_AT", truncate:
        s = strfind( svr, '_' );
        if ~isempty(s), svr = svr(s+1:end); end
        opts.alg = svr;
    end
end




nonneg = false;
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
    prox    = prox_l1pos;
else
    % -- case: no x >= 0 constraint
    prox    = prox_l1;
end
[varargout{1:max(nargout,1)}] = ...
    tfocs_SCD( prox, { A, -b }, prox_l2( epsilon ), mu, x0, z0, opts, varargin{:} );



% TFOCS v1.3 by Stephen Becker, Emmanuel Candes, and Michael Grant.
% Copyright 2013 California Institute of Technology and CVX Research.
% See the file LICENSE for full license information.

