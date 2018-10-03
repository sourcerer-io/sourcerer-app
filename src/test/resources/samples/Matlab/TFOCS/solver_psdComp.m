function [ x, out, opts ] = solver_psdComp( Xinc, opts )
% SOLVER_PSDCOMP Matrix completion for PSD matrices.
% [ x, out, opts ] = solver_psdComp( Xinc, opts )
%    Solves the PSD matrix completion problem
%        minimize (1/2)*norm(X(ij)-vv).^2
%        s.t.     X p.s.d
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
%   Set opts.largescale=true to use eigs() instead if eig().
%
% See also solver_psdCompConstrainedTrace

% Supply default values
error(nargchk(1,2,nargin));
if nargin < 2, opts = []; end
if ~isfield( opts, 'restart' ), 
    opts.restart = 50; 
end
if isfield( opts, 'symmetrize' ), 
    symmetrize = opts.symmetrize;
    opts = rmfield(opts,'symmetrize');
else
    symmetrize = false;
end
if isfield( opts, 'largescale' ), 
    largescale = opts.largescale;
    opts = rmfield(opts,'largescale');
else
    largescale = false;
end
[n,m] = size(Xinc);
if n ~= m, error( 'Input must be square.' ); end

if norm(Xinc-Xinc','fro') > 1e-8*norm(Xinc,'fro') && symmetrize
    Xinc    = symmetrizeSparseMatrix(Xinc);
    disp('symmetrizing input');
end
linop = linop_subsample(Xinc);
vv    = full( Xinc( find(Xinc) ) );

[x,out,opts] = tfocs( smooth_quad, { linop, -vv }, proj_psd(largescale), Xinc, opts );


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
