function varargout = solver_sDantzig_W( A,W, b, delta, mu, x0, z0, opts, varargin )
% SOLVER_SDANTZIG_W Weighted Dantzig selector problem. Uses smoothing.
%[ x, out, opts ] = solver_sDantzig_W( A,W, b, delta, mu, x0, z0, opts )
%    Solves the smoothed Dantzig
%        minimize norm(W*x,1) + (1/2)*mu*norm(x-x0).^2
%        s.t.     norm(D.*(A'*(A*x-b)),Inf) <= delta
%    by constructing and solving the composite dual
%
%    A and W must be a linear operator, b must be a vector, and delta and mu
%    must be positive scalars. Initial points x0 and z0 are optional.
%    The standard calling sequence assumes that D=I. To supply a scaling,
%    pass the cell array { A, D } instead of A. D must either be a scalar,
%    a vector of weights, or a linear operator.
%
%   Pass in the options "normA2" and "normW2" (which are ||A||^2
%       and ||W||^2 respectively) for best efficiency.
%
%   See also solver_sDantzig

% Supply default values
error(nargchk(5,9,nargin));
if nargin < 6, x0   = []; end
if nargin < 7, z0   = []; end
if nargin < 8, opts = []; end

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

% Extract the linear operators
D = [];
if isa( A, 'cell' ),
    if length(A) > 1, D = A{2}; end
    A = A{1};
end
if isempty(D),
    D = @(x)x;
elseif isa( D, 'double' ),
    D = @(x)D.*x;
end
if isa( A, 'double' ),
    % if "A" is not too rectangular, it is probably more efficient
    %   to compute A'*A once at the beginning and store it.
    mn  = min(size(A));
    mx  = max(size(A));
    if mn >= .7*mx && mx < 1e5
        AA = @(y,mode)linear_DS_AA( D, A'*A, y, mode );
        A = linop_matrix(A);
    else
        A = linop_matrix(A);
        AA = @(y,mode)linear_DS( D, A, y, mode );
    end
else
    AA = @(y,mode)linear_DS( D, A, y, mode );
end

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

% Call TFOCS
proxScale   = sqrt( normW2 / normA2 );
prox        = { prox_l1( delta ); proj_linf(proxScale) };
W           = linop_compose( W, 1/proxScale);
affineF     = {AA, -D(A(b,2)); W, 0 };
[varargout{1:max(nargout,1)}] = ...
    tfocs_SCD( [], affineF, prox, mu, x0, z0, opts, varargin{:} );


% Implements x -> D*A'*A*x and its adjoint if A is a linop
function y = linear_DS( D, A, y, mode )
switch mode,
case 0, 
    y = A([],0);
    if iscell( y ),
        y = { y{1}, y{1} };
    else
        y = { [y(2),1], [y(2),1] };
    end
case 1, y = D(A(A(y,1),2));
case 2, y = A(A(D(y),1),2);
end

function y = linear_DS_AA( D, AA, y, mode )
% similar to above, but expects AA to be an explicit Hermitian matrix
switch mode,
case 0, 
    y = size(AA);
    if iscell( y ),
        y = { y{1}, y{1} };
    else
        y = { [y(2),1], [y(2),1] };
    end
case 1, y = D(AA*y);
case 2, y = AA*D(y);
end

% TFOCS v1.3 by Stephen Becker, Emmanuel Candes, and Michael Grant.
% Copyright 2013 California Institute of Technology and CVX Research.
% See the file LICENSE for full license information.

