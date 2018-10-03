function varargout = solver_sBPDN_WW( A, alpha, W1, beta, W2, b, epsilon, mu, x0, z0, opts, varargin )
% SOLVER_SBPDN_WW BPDN with two separate (weighted) l1-norm terms. Uses smoothing.
% [ x, out, opts ] = solver_sBPDN_WW( A, alpha, W_1, beta, W_2, b, epsilon, mu, x0, z0, opts )
%    Solves the smoothed basis pursuit denoising problem
%        minimize alpha*norm(W_1 x,1) + beta*norm(W_2 x, 1) + 0.5*mu*(x-x0).^2
%        s.t.     norm(A*x-b,2) <= epsilon
%    by constructing and solving the composite dual.
%    A, W_1 and W_2 must be a linear operator or matrix, and b must be a vector. The
%    initial points x0, z0 and the options structure opts are optional.
%    See also solver_sBPDN and solver_sBPDN_W

% Supply default values
error(nargchk(8,12,nargin));
if nargin < 9, x0 = []; end
if nargin < 10, z0 = []; end
if nargin < 11, opts = []; end
if ~isfield( opts, 'restart' ), opts.restart = 5000; end

if epsilon < 0
    error('TFOCS error: epsilon is negative');
end
if ~epsilon
    error('TFOCS error: cannot handle epsilon = 0.  Please call solver_sBP instead');
elseif epsilon < 100*builtin('eps')
    warning('TFOCS:badConstraint',...
        'TFOCS warning: epsilon is near zero; consider calling solver_sBP instead');
end

% Need to estimate the norms of A*A' and W*W' in order to be most efficient
if isfield( opts, 'noscale' ) && opts.noscale,
    normA2 = 1; normW12 = 1; normW22 = 1;
else
    normA2 = []; normW12 = []; normW22 = [];
    if isfield( opts, 'normA2'  )
        normA2 = opts.normA2;
        opts = rmfield( opts, 'normA2' );
    end
    if isfield( opts, 'normW12' )
        normW12 = opts.normW12;
        opts = rmfield( opts, 'normW12' );
    end
    if isfield( opts, 'normW22' )
        normW22 = opts.normW22;
        opts = rmfield( opts, 'normW22' );
    end
end
if isempty( normA2 ),
    normA2 = linop_normest( A ).^2;
end
if isempty( normW12 ),
    normW12 = linop_normest( W1 ).^2;
end
if isempty( normW22 ),
    normW22 = linop_normest( W2 ).^2;
end
if isempty(alpha), 
    alpha = 1; 
end
if isempty(beta), 
    beta = 1; 
end

proxScale1 = sqrt( normW12 / normA2 );
proxScale2 = sqrt( normW22 / normA2 );
prox       = { prox_l2( epsilon ), ...
               proj_linf( proxScale1 * alpha ),...
               proj_linf( proxScale2 * beta ) };
W1         = linop_compose( W1, 1 / proxScale1 );
W2         = linop_compose( W2, 1 / proxScale2 );
[varargout{1:max(nargout,1)}] = ...
    tfocs_SCD( [], { A, -b; W1, 0; W2, 0 }, prox, mu, x0, z0, opts, varargin{:} );


% TFOCS v1.3 by Stephen Becker, Emmanuel Candes, and Michael Grant.
% Copyright 2013 California Institute of Technology and CVX Research.
% See the file LICENSE for full license information.

