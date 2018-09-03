function varargout = solver_sDantzig( A, b, delta, mu, x0, z0, opts, varargin )
% SOLVER_SDANTZIG Dantzig selector problem. Uses smoothing.
%[ x, out, opts ] = solver_sDantzig( A, b, delta, mu, x0, z0, opts )
%    Solves the smoothed Dantzig
%        minimize norm(x,1) + (1/2)*mu*norm(x-x0).^2
%        s.t.     norm(D.*(A'*(A*x-b)),Inf) <= delta
%    by constructing and solving the composite dual
%        maximize - g_sm(z) - delta*norm(z,1)
%    where
%        gsm(z) = sup_x <z,D.*A'*(Ax-b)>-norm(x,1)-(1/2)*mu*norm(x-x0)
%    A must be a linear operator, b must be a vector, and delta and mu
%    must be positive scalars. Initial points x0 and z0 are optional.
%    The standard calling sequence assumes that D=I. To supply a scaling,
%    pass the cell array { A, D } instead of A. D must either be a scalar,
%    a vector of weights, or a linear operator.

% Supply default values
error(nargchk(4,8,nargin));
if nargin < 5, x0   = []; end
if nargin < 6, z0   = []; end
if nargin < 7, opts = []; end

% -- legacy options from original software --
if isfield(opts,'lambda0')
    z0 = opts.lambda0;
    opts = rmfield(opts,'lambda0');
end
if isfield(opts,'xPlug')
    x0 = opts.xPlug;
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
    A = linop_matrix(A);
end

% Call TFOCS
objectiveF = prox_l1;
affineF    = { @(y,mode)linear_DS( D, A, y, mode ), -D(A(b,2)) };
dualproxF  = prox_l1( delta );
[varargout{1:max(nargout,1)}] = ...
    tfocs_SCD( objectiveF, affineF, dualproxF, mu, x0, z0, opts, varargin{:} );

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

% TFOCS v1.3 by Stephen Becker, Emmanuel Candes, and Michael Grant.
% Copyright 2013 California Institute of Technology and CVX Research.
% See the file LICENSE for full license information.

