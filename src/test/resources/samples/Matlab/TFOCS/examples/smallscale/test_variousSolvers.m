%{
Solves a simple quadratic problem
(with optimal solution known in closed-form)
with all the various solvers


the quadratic problem is:

min_x  c'x + x'Px/2, P > 0, hence the optimal solution is x = -inv(Q)*c

On a simple quadratic example like this, when there is no projection,
all the solver behave similarly. So this script is more useful for debugging
to make sure that all solvers are working

%}

%% Make a problem
N   = 100;
randn('state',2334);
P   = randn(N); P = P*P' + .1*eye(N); % ensure P is symmetric positive definite
c   = randn(N,1);

x_ref   = -P\c;

%% Solve with TFOCS
f   = smooth_quad( P, c );
affine    = [];
projector = [];
x0        = zeros(N,1);
opts      = [];
opts.printEvery     = 500;
opts.tol  = 1e-8;
opts.printStopCrit  = true;
opts.restart    = 350;  % use this since the problem is strongly convex
opts.errFcn     = @(f,x) norm( x-x_ref)/norm(x_ref);
opts.maxIts     = 750;

% The 'N83' and 'AT' methods can take advantage when you know
%   the exact value of the strong convexity parameter
%   (and the Lipschitz constant).  In this case, do not
%   use restart. But we won't test this right now, 
%   since it is unusual that you have information
%   about the strong convexity constant.
% opts.restart    = Inf;
% opts.mu         = min(eig(P)); % strong convexity parameter. N83 can make use of this
% opts.Lexact     = max(eig(P));

solverList = { 'GRA', 'AT', 'LLM', 'N07', 'N83', 'TS' };
% solverList = { 'GRA', 'AT', 'N83', 'TS' };
% solverList = { 'LLM','N07'}; % these take two steps per iteration

figure(1); clf;

for k = 1:length( solverList )
    solver  = solverList{k};
    opts.alg    = solver;
    fprintf('\nSolver: %s\n\n', solver );
    [x,out,optsOut] = tfocs( f, affine, projector, x0, opts );
    semilogy( out.err );
    hold all
end
legend( solverList );


%% close all figures
close all

% TFOCS v1.3 by Stephen Becker, Emmanuel Candes, and Michael Grant.
% Copyright 2013 California Institute of Technology and CVX Research.
% See the file LICENSE for full license information.