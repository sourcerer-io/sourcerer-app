function varargout = solver_sBP( A, b, mu, x0, z0, opts, varargin )
% SOLVER_SBP Basis pursuit (l1-norm with equality constraints). Uses smoothing.
% [ x, out, opts ] = solver_sBP( A, b, mu, x0, z0, opts )
%    Solves the smoothed basis pursuit problem
%        minimize norm(x,1) + 0.5*mu*(x-x0).^2
%        s.t.     A * x == b
%    by constructing and solving the composite dual
%        maximize - g_sm(z)
%    where
%        g_sm(z) = sup_x <z,Ax-b>-norm(x,1)-(1/2)*mu*norm(x-x0)
%    A must be a linear operator or matrix, and b must be a vector. The
%    initial point x0 and the options structure opts are optional.
%
%    If "nonneg" is a field in "opts" and opts.nonneg is true,
%       then the constraints are   A * x == b   AND  x >= 0

% Supply default values
error(nargchk(3,7,nargin));
if nargin < 4, x0 = []; end
if nargin < 5, z0 = []; end
if nargin < 6, opts = []; end
if ~isfield( opts, 'restart' ), opts.restart = 400; end


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
    tfocs_SCD( prox, { A, -b }, proj_Rn, mu, x0, z0, opts, varargin{:} );
    

% TFOCS v1.3 by Stephen Becker, Emmanuel Candes, and Michael Grant.
% Copyright 2013 California Institute of Technology and CVX Research.
% See the file LICENSE for full license information.

