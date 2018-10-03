function [ x, odata, opts ] = solver_TraceLS( A, b, lambda, x0, opts )
% SOLVER_TRACELS Unconstrained form of trace-regularized least-squares problem.
% [ x, odata, opts ] = solver_TraceLS( A, b, lambda, x0, opts )
%    Solves the trace-regularized least squares problem
%        minimize (1/2)*norm( A * X - b )^2 + lambda * trace( X )
%        with the constraint that X is positive semi-definite.
%    A must be a matrix or a linear operator, b must be a vector, 
%    and lambda must be a real positive scalar. 
%    The initial point x0 and option structure opts are
%    both optional.
%
%    If "A" is a sparse matrix, and nnz(Z) = length(b), then it is assumed
%    that the nonzero entries correspond to samples, and then the
%    corresponding sampling operator is used.
%
%    If opts.largescale = true, then uses an iterative method
%    to compute the eigenvalue decomposition used with prox_trace.
%
%   See also solver_L1RLS (aka The Lasso)


% Added Feb 7, 2011
error(nargchk(3,5,nargin));
if nargin < 4, x0 = []; end
if nargin < 5, opts = []; end
if ~isfield( opts, 'restart' ), 
    opts.restart = 100; 
end
if issparse(A) && nnz(A) == length(b)
    A = linop_subsample(A);
end
if isfield( opts,'largescale')
    prx = prox_trace( lambda, opts.largescale );
    opts = rmfield(opts,'largescale');
else
    prx = prox_trace( lambda );
end
% Note: the proximity operator of trace is really a combination
%  of the proximity operator of trace and the indicator
%  set of positive semi-definite matrices.
%  So we do not need to *explicitly* include the positive semi-definite constraint.

[x,odata,opts] = tfocs( smooth_quad, { A, -b }, prx, x0, opts );

% TFOCS v1.3 by Stephen Becker, Emmanuel Candes, and Michael Grant.
% Copyright 2013 California Institute of Technology and CVX Research.
% See the file LICENSE for full license information.

