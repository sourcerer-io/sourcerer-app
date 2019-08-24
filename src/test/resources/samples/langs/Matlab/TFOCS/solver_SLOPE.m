function [ x, odata, opts ] = solver_SLOPE( A, b, lambda, x0, opts )
% SOLVER_SLOPE Sorted l1-regularized least squares problem, 
% [ beta, odata, opts ] = solver_SLOPE( X, y, lambda, beta0, opts )
%    Solves the l1-regularized least squares problem, using the sorted/ordered l1 norm, 
%        minimize (1/2)*norm( A * x - b )^2 + norm( lasso.*sort(abs(x),'descend'), 1 )
%    using the Auslender/Teboulle variant with restart. X must be a matrix
%    or a linear operator, y must be a vector, and lambda must be a real
%    positive vector in decreasing order. 
%    The initial point beta0 and option structure opts are both optional.
%
% SLOPE stands for Sorted L-One Penalized Estimation
%
% Reference:
%   "Statistical Estimation and Testing via the Ordered l1 Norm"
%   by M. Bogdan, E. van den Berg, W. Su, and E. J. Candès, 2013
%   http://www-stat.stanford.edu/~candes/OrderedL1/
%
%   See also solver_L1RLS.m, solver_LASSO.m, prox_Sl1.m

error(nargchk(3,5,nargin));
if nargin < 4, x0 = []; end
if nargin < 5, opts = []; end
if ~isfield( opts, 'restart' ), 
    opts.restart = 100; 
end

[x,odata,opts] = tfocs( smooth_quad, { A, -b }, prox_Sl1( lambda ), x0, opts );

% TFOCS v1.3 by Stephen Becker, Emmanuel Candes, and Michael Grant.
% Copyright 2013 California Institute of Technology and CVX Research.
% See the file LICENSE for full license information.

