function varargout = solver_sNuclearBPDN( omega, b, epsilon, mu, x0, z0, opts, varargin )
% SOLVER_SNUCLEARBPDN Nuclear norm basis pursuit problem with relaxed constraints. Uses smoothing.
% [ x, out, opts ] = solver_sNuclearBPDN( omega, b, epsilon,mu, X0, Z0, opts )
%    Solves the smoothed nuclear norm basis pursuit problem
%        minimize norm_nuc(X) + 0.5*mu*norm(X-X0,'fro').^2
%        s.t.     ||A_omega * x - b || <= epsilon
%    by constructing and solving the composite dual
%        maximize - g_sm(z)
%    where
%        g_sm(z) = sup_x <z,Ax-b>-norm(x,1)-(1/2)*mu*norm(x-x0)
%    A_omega is the restriction to the set omega, and b must be a vector. The
%    initial point x0 and the options structure opts are optional.
%
%   The "omega" term may be in one of three forms:
%       (1) OMEGA, a sparse matrix.  Only the nonzero pattern is important.
%       (2) {n1,n2,omega}, a cell, where [n1,n2] = size(X), and omega
%               is the vector of linear indices of the observed set
%       (3) {n1,n2,omegaI,omegaJ}, a cell.  Similar to (2), except the set
%               omega is now specified by subscripts. Specifically,
%               omega = sub2ind( [n1,n2], omegaI, omegaJ) and
%               [omegaI,omegaJ] = ind2sub( [n1,n2], omega )

% Supply default values
error(nargchk(4,8,nargin));
if nargin < 5, x0 = []; end
if nargin < 6, z0 = []; end
if nargin < 7, opts = []; end
if ~isfield( opts, 'restart' ), 
    opts.restart = 50; 
end

if isempty(omega)
    error( 'Sampling operator cannot be empty.' );
elseif issparse(omega)
    [omegaI,omegaJ] = find(omega);
    [n1,n2]         = size(omega);
    omega_lin       = sub2ind( [n1,n2], omegaI, omegaJ );
elseif iscell(omega)
    switch length(omega)
    case 3,
        [ n1, n2, omega_lin ] = deal( omega{:} );
        [omegaI,omegaJ]       = ind2sub( [n1,n2], omega_lin );
    case 4
        [ n1, n2, omegaI, omegaJ ] = deal( omega{:} );
        omega_lin = sub2ind( [n1,n2], omegaI, omegaJ );
    otherwise
        error( 'Incorrect format for the sampling operator.' );
    end
else
    error( 'Incorrect format for the sampling operator.' );
end
nnz = numel(omega_lin);
if ~isequal( size(b), [ nnz, 1 ] ),
    error( 'Incorrect size for the sampled data.' );
end

% TODO: see the new linop_subsample.m file
A = @(varargin)linop_nuclear( n1, n2, nnz, omega_lin, omegaI, omegaJ, varargin{:} );
[varargout{1:max(nargout,1)}] = ...
    tfocs_SCD( prox_nuclear, { A, -b }, prox_l2(epsilon), mu, x0, z0, opts, varargin{:} );

%
% Implements the matrix sampling operator: X -> [X_ij]_{i,j\in\omega}
%
function y = linop_nuclear( n1, n2, nnz, omega, omegaI, omegaJ, x, mode )
switch mode,
    case 0,
        y = { [n1,n2], [nnz,1] };
    case 1,
        y = x(omega);
    case 2,
        y = sparse( omegaI, omegaJ, x, n1, n2 );
end

% TFOCS v1.3 by Stephen Becker, Emmanuel Candes, and Michael Grant.
% Copyright 2013 California Institute of Technology and CVX Research.
% See the file LICENSE for full license information.

