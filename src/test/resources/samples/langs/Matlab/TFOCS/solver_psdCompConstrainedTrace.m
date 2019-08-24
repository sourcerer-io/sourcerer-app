function [ x, out, opts ] = solver_psdCompConstrainedTrace( Xinc, tr, opts )
% SOLVER_PSDCOMPCONSTRAINEDTRACE Matrix completion with constrained trace, for PSD matrices.
% [ x, out, opts ] = solver_psdCompConstrainedTrace( Xinc, tr, opts )
%    Solves the PSD matrix completion problem
%        minimize (1/2)*norm(X(ij)-vv).^2
%        s.t.     X p.s.d and trace(X) = tr
%    where ij is a vector of indices corresponding to the known elements.
%    The nonzero values of Xinc are assumed to be the known values; that
%    is, all zero values are considered unknowns. In order to specify a
%    known zero value, replace it with a very small value; e.g., 1e-100.
%
%   Since X must be symmetric, the ij entries should have symmetry. If they
%   are not specified symmetrically, then choose opts.symmetrize = true
%   to force them to become symmetric. This will change the objective
%   function.
%
%   See also solver_psdComp

% Supply default values
error(nargchk(1,3,nargin));
if nargin < 3, opts = []; end
if ~isfield( opts, 'restart' ), 
    opts.restart = 50; 
end
if isfield( opts, 'symmetrize' ), 
    symmetrize = opts.symmetrize;
    opts = rmfield(opts,'symmetrize');
else
    symmetrize = false;
end
if nargin < 2 || isempty(tr)
    tr = 1;
end

[n,m] = size(Xinc);
if n ~= m, error( 'Input must be square.' ); end
% If not symmetric, then make it symmetric
if norm(Xinc-Xinc','fro') > 1e-8*norm(Xinc,'fro') && symmetrize
    Xinc = symmetrizeSparseMatrix(Xinc);
    disp('symmetrizing input');
end

% -- This doesn't work so well --
% Xinc = tril(Xinc);
% [ii,jj,vv] = find(Xinc);
% ij = sub2ind( [n,n], ii, jj );
% linop = @(varargin)samp_op( n, ii, jj, ij, varargin{:} );
% 
% Xinc = Xinc + tril(Xinc,-1)';

% This is better:
linop = linop_subsample(Xinc);
vv    = full( Xinc( find(Xinc) ) );

% Extract the linear operators
[x,out,opts] = tfocs( smooth_quad, { linop, -vv }, proj_psdUTrace(tr), Xinc, opts );

% we use a special sampling operator to tell it to make it symmetric
function y = samp_op( n, ii, jj, ij, X, mode )
switch mode
    case 0,
        y = { [n,n], [length(ii),1] };
    case 1,
        X = (X+X')/2;
        y = full(X(ij)); %otherwise it is a sparse vector 
    case 2,
        y = sparse( ii, jj, X, n, n );
        y = y + tril(y,-1)';
end

function X = symmetrizeSparseMatrix( X )
    %   Some entries were only specified once, others were
    %   double-specified, so we don't know if we should
    %   divide by 1 or 2
    ind1 = find( tril(X) );
    ind2 = find( tril(X',-1) );
    X    = tril(X) + tril( X', -1);
    ind  = intersect(ind1,ind2);
    X(ind) = X(ind)/2;
    X    = X + tril(X,-1)';

% TFOCS v1.3 by Stephen Becker, Emmanuel Candes, and Michael Grant.
% Copyright 2013 California Institute of Technology and CVX Research.
% See the file LICENSE for full license information.
