%{
This file shows an example of using the full power of TFOCS. If you
are not familiar with basic usage of TFOCS, please see other demos
first.

We make an example that uses:
    -several variables (2), and the variables are matrices, not just vectors
    -several constraints (4)
    -affine operators (linear plus offset), and two of the operators
        are matrix --> matrix operators
    -debug mode


For small complicated examples like this, TFOCS is not necessarily
faster than software like CVX, since it takes more iterations than an
interior point method and there is some overhead in the TFOCS software
since the software is meant for flexibility rather than absolute speed.

However, if you take any complicated problem and scale the size by a factor
of 100, then CVX won't be able to handle it at all. TFOCS will do
just fine (and it might even be less than 100x as slow, since now the overhead
is not significant).


The problem we will solve:

min_{X1, X2} smooth1(X1)+smooth2(X2) +  sum_{i=1}^4  g_i( A1_i*X1 + A2_i*X2 + B_i )

meaning that we have 2 variables (X1 and X2), both of which are matrices,
and each variable has its own smooth function.
For non-smooth and/or constraint terms (indexed by "i"), we have 4 functions
( i = 1,2,3,4) g_i, and each has it's own affine operator in X1 and X2.
So each of the 4 affine operators has three parts: the portion linear in X1,
the portion linear in X2, and the constant offset "B_i".

To be explicit, the smooth functions are linear and quadratic, resp.:

smooth1(X1) = dot( s1, X1 ) + 3.4                  ("s1" is a matrix the same size as X1)
smooth2(X2) = dot( X2, X2 ) + dot( s2, X2 ) + 4.5  ("s2" is a matrix the same size as X2)

and the non-smooth/constraint terms are:

g_1(z)  = indicator set of the positive orthant of R^10
g_2(z)  = ||z||_2 (usual Euclidean norm) in R^15
g_3(z)  = ||z||_1 (l1 norm) in R^{10 x 20 }. This views a 10 x 20 matrix as a 200 x 1 vector.
g_4(z)  = indicator set of positive orthant of R^{20 x 22 }, i.e. each element must be >= 0 coordinate-wise

The affine operators are picked arbitrary, but some of them (#3 and #4) have a range that
is a set of matrices, rather than a set of vectors, in order to make 
this more interesting.

%}

fileName = fullfile('reference_solutions','complicatedProblem1');
randn('state',29324);
rand('state',9332);
% rng(3481); % this only works on new versions of Matlab

% -- Variables --
% Two sets of variables, X1 (a matrix of size n1 x n2 ) and X2 (matrix of N1 x N2 )
n1 = 10; n2 = 20;
N1 = 12; N2 = 18;
X1 = zeros( n1, n2 );
X2 = zeros( N1, N2 );

% -- the smooth terms -- 
%   Note: the inner product used is the matrix inner product
%       that induces the Frobenius norm.
s1      = randn(n1,n2);
smooth1 = smooth_linear( s1, 3.4 );
s2      = randn(N1,N2);
smooth2 = smooth_quad( 1, s2, 4.5 );
% and the same thing, but in a format that CVX likes:
smoothF = @(X1,X2) vec(X1)'*vec(s1) + 3.4 + vec(X2)'*vec(s2) + 4.5 + ...
    sum_square(vec(X2))/2;

% -- some proximal terms --

nProx   = 4;
prox1   = proj_Rplus;
prox2   = proj_l2;          % primal is norm( , 2)
prox3   = proj_linf(1);     % this can take matrix varaibles...
prox4   = proj_Rplus;       % this can take matrix variables...
% Sizes of proxes (i.e. sizes of dual variables, i.e. size of range of linear terms)
d1      = [ 10, 1  ];
d2      = [ 15, 1  ];
d3      = [ n1, n2 ];
d4      = [ 20, 22 ];


% -- and linear terms --

% for prox1:
const1  = randn(d1);
temp1   = randn( prod(d1), n1*n2);
A1_X1   = linop_compose( linop_matrix(temp1), linop_vec([n1,n2]) );
temp2   = randn( prod(d1), N1*N2);
A1_X2   = linop_compose( linop_matrix(temp2), linop_vec([N1,N2]) );

A1      = @(X1,X2) temp1*vec(X1) + temp2*vec(X2) + const1;

% for prox2: (matrix variable)
const2  = randn(d2);
temp1   = randn( prod(d2), n1*n2);
A2_X1   = linop_compose( linop_matrix(temp1), linop_vec([n1,n2]) );
temp2   = randn( prod(d2), N1*N2);
A2_X2   = linop_compose( linop_matrix(temp2), linop_vec([N1,N2]) );

A2      = @(X1,X2) temp1*vec(X1) + temp2*vec(X2) + const2;

% for prox3:
const3  = 0;
A3_X1   = 63.4;     % this represents abstract scaling, i.e. any size input
A3_X2   = 0;        % this reprsents the zero linear operator

A3      = @(X1,X2) A3_X1*X1;

% for prox4: (matrix variable)
const4  = randn(d4);
temp1   = randn( prod(d4), n1*n2);
A4_X1   = linop_compose( linop_matrix(temp1), linop_vec([n1,n2]) );
rs      = linop_adjoint( linop_vec(d4) );
A4_X1   = linop_compose( rs, A4_X1 );
mat1    = @(x) reshape( x, d4(1), d4(2) );

temp2   = randn( prod(d4), N1*N2);
A4_X2   = linop_compose( linop_matrix(temp2), linop_vec([N1,N2]) );
rs      = linop_adjoint( linop_vec(d4) );
A4_X2   = linop_compose( rs, A4_X2 );

A4      = @(X1,X2) mat1( temp1*vec(X1) + temp2*vec(X2) ) + const4;

% -- set the smoothing parameter --
mu = 1;

if exist([fileName,'.mat'],'file')
    load(fileName); % contains X_CVX
    fprintf('Loaded problem from %s\n', fileName );
else
    % Get reference solution in CVX
    % First, get a solution to the smoothed version:
    cvx_begin
        variables X1(n1,n2) X2(N1,N2)
        % it's important that we use norm(vec(...),1) and not just norm(...,1),
        %   otherwise CVX interprets this with the wrong implicit inner product
        minimize(     smoothF( X1, X2 ) + ...
            norm( A2(X1,X2), 2 ) + norm( vec(A3(X1,X2)) , 1 ) + ...
            mu*( sum_square(vec(X1)) + sum_square(vec(X2)) )/2       )
        subject to
            A1(X1,X2) >= 0  % constraint is dual of prox1
            A4(X1,X2) >= 0  % constraint is dual of prox2
    cvx_end
    X_CVX_smoothed{1} = X1;
    X_CVX_smoothed{2} = X2;
    
    % Second, get a solution to the unsmoothed version
    cvx_begin
        variables X1(n1,n2) X2(N1,N2)
        minimize(     smoothF( X1, X2 ) + ...
            norm( A2(X1,X2), 2 ) + norm( vec(A3(X1,X2)) , 1 ) )
        subject to
            A1(X1,X2) >= 0
            A4(X1,X2) >= 0
    cvx_end
    X_CVX{1} = X1;
    X_CVX{2} = X2;
    
    save(fileName,'X_CVX', 'X_CVX_smoothed');
    fprintf('Saved data to file %s\n', fileName);
end

% Verify constraint are satisfied
fprintf('Is A1(x1,x2) >= 0? The min element is %g\n', min(    A1(X_CVX{1},X_CVX{2} )) )
fprintf('Is A2(x1,x2) >= 0? The min element is %g\n', min(min(A4(X_CVX{1},X_CVX{2}))) )
%% before running TFOCS, scale the problem perhaps?
% This is one way to see how big the norms are:
% nrm11    = linop_test( A1_X1 ); % 15.7
% nrm12    = linop_test( A1_X2 ); % 16.6
% 
% nrm21    = linop_test( A2_X1 ); % 17.8
% nrm22    = linop_test( A2_X2 ); % 18.6
% 
% nrm31    = linop_test( A3_X1 ); % 63.4
% nrm32    = linop_test( A3_X2 ); % 0
% 
% nrm41    = linop_test( A4_X1 ); % 35.6
% nrm42    = linop_test( A4_X2 ); % 34.6

%% now, run TFOCS. First, try it without continuation

x0 = [];
z0 = [];
opts    = struct('continuation',false,'maxits',1500,'debug',true); % using 'debug' mode to print out useful information
opts.printEvery     = 50;

% Pick a scaling factor "s" (optional: set to "1" to have no effect)
s = .5; % helps a little bit
% (note that if we scale prox3 by "s", then we multiply the corresponding
%  affine part by "s", rather than divide them by "s", since prox3
%  is really for the dual and not the primal).

mu  = 1;
opts.errFcn{1} = @(f,d,p) norm( p{1}-X_CVX_smoothed{1}); % compare to smoothed reference solution
opts.errFcn{2} = @(f,d,p) norm( p{2}-X_CVX_smoothed{2});

[xAll,outParam,optsOut] = tfocs_SCD( {smooth1,smooth2}, ...
    { A1_X1, A1_X2, const1; A2_X1, A2_X2, const2; ...
    A3_X1*s, A3_X2*s, const3*s; A4_X1, A4_X2, const4 }, ...
    {prox1,prox2,prox_scale(prox3,s),prox4},...
    mu, x0, z0, opts );

mnConstraint1    = min(min( A1(xAll{1},xAll{2} ) ) );
mnConstraint2    = min(min( A4(xAll{1},xAll{2} ) ) );
fprintf('First constraint violated by:   %g\n', mnConstraint1);
fprintf('Second constraint violated by:  %g\n', mnConstraint2 );

% Check that we are within acceptable limits
er = sqrt(norm( xAll{1} - X_CVX_smoothed{1} )^2 + norm( xAll{2} - X_CVX_smoothed{2} )^2 )/...
    sqrt( norm(X_CVX_smoothed{1})^2 + norm(X_CVX_smoothed{2})^2 ); % should be about .006

if er > 0.04 || mnConstraint1 < -.01 || mnConstraint2 < -.01
    error('Failed the test');
else
    disp('This test successfully passed');
end

%% run TFOCS with continuation
x0 = [];
z0 = [];
% type "tfocs" at the command to see possible options
opts    = struct('continuation',true,'maxits',1500);
opts.printEvery     = 50;
opts.tol            = 1e-4;
opts.stopCrit       = 4;
opts.printStopCrit  = true;

% type "continuation" at the command to see possible options
contOpts    = struct( 'maxIts', 8 , 'muDecrement', 0.8 );
% ask for increased accuracy on the final solve
contOpts.finalTol = 1e-5;

s = .5; % helps a little bit
% (note that if we scale prox3 by "s", then we multiply the corresponding
%  affine part by "s", rather than divide them by "s", since prox3
%  is really for the dual and not the primal).

mu  = 10;
opts.errFcn{1} = @(f,d,p) norm( p{1}-X_CVX{1}); % compare to unsmoothed reference solution
opts.errFcn{2} = @(f,d,p) norm( p{2}-X_CVX{2});

[xAll,outParam,optsOut] = tfocs_SCD( {smooth1,smooth2}, ...
    { A1_X1, A1_X2, const1; A2_X1, A2_X2, const2; ...
    A3_X1*s, A3_X2*s, const3*s; A4_X1, A4_X2, const4 }, ...
    {prox1,prox2,prox_scale(prox3,s),prox4},...
    mu, x0, z0, opts, contOpts );

mnConstraint1    = min(min( A1(xAll{1},xAll{2} ) ) );
mnConstraint2    = min(min( A4(xAll{1},xAll{2} ) ) );
fprintf('First constraint violated by:   %g\n', mnConstraint1);
fprintf('Second constraint violated by:  %g\n', mnConstraint2 );

% Check that we are within acceptable limits
er = sqrt(norm( xAll{1} - X_CVX{1} )^2 + norm( xAll{2} - X_CVX{2} )^2 )/...
    sqrt( norm(X_CVX{1})^2 + norm(X_CVX{2})^2 ); % should be about .006

if er > 0.4 || mnConstraint1 < -.01 || mnConstraint2 < -.01
    error('Failed the test');
else
    disp('This test successfully passed');
end

% TFOCS v1.3 by Stephen Becker, Emmanuel Candes, and Michael Grant.
% Copyright 2013 California Institute of Technology and CVX Research.
% See the file LICENSE for full license information.