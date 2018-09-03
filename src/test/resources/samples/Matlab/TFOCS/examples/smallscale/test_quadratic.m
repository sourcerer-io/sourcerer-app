%% Tests the solvers on a simple unconstrained quadratic function

%{
    Solve:

    minimize_x  c'x + x'Dx/2

    as an example of using TFOCS without the "SCD" interface

%}

randn( 'state', sum('quadratic test') );
N       = 100;
c       = randn(N,1);
D       = randn(N,N);
D       = D * D' + .5*eye(N);
x_star  = - D \ c;          % the true answer
x0      = zeros(N,1);

% Here's what you could do...
% f       = @(x) c'*x + x'*D*x/2;
% grad_f  = @(x) c + D*x;
% smoothF = @(x) wrapper_objective( f, grad_f, x );

% Here's a simpler way:
smoothF = smooth_quad(D,c);

x_error = @(x) norm(x-x_star,Inf);

opts = [];
opts.errFcn     = { @(f,x) x_error(x)};
opts.restart = 100;

[ x, out, optsOut ] = tfocs( smoothF, [], [],x0, opts );
% Check that we are within allowable bounds
if out.err(end) < 1e-5
    disp('Everything is working');
else
    error('Failed the test');
end

% TFOCS v1.3 by Stephen Becker, Emmanuel Candes, and Michael Grant.
% Copyright 2013 California Institute of Technology and CVX Research.
% See the file LICENSE for full license information.
