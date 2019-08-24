%{
   Support Vector Machine (SVM) example

    This is not a largescale test but it's neat, so it's in this directory

    We have binary data, and the two classes are labeled +1 and -1
    The data is d-dimensional, and we have n samples


    This example show show to solve the standard SVM using the hinge-loss
    and l2 penalty. Then it shows how it is easy with TFOCS to generalize
    the SVM problem and use the l1 penalty instead of the l2 penalty,
    which has the effect of encouraging sparsity.

%}

% Before running this, please add the TFOCS base directory to your path


% Generate a new problem

randn('state',23432);
rand('state',3454);

n = 30;
d = 2; % 2D data is nice because it's easy to visualize

n1 = round(.5*n);   % number of -1 (this is data from one "class")
n2 = n - n1;        % number of +1 (this is data from the other "class")

% Generate data
mean1   = [-.5,1];
% mean2   = [.6,.2]; % can be separated
mean2   = [.1,.5]; % cannot be separated, so a bit more interesting
s       = .25;  % standard deviation
x1  = repmat(mean1,n1,1) + s*randn(n1,2);
x2  = repmat(mean2,n2,1) + s*randn(n2,2);

X = [x1; x2];
labels = [ ones(n1,1); -ones(n2,1) ];

figure(1); clf;
hh = {};
hh{1}=plot(x1(:,1), x1(:,2), 'o' );
hold all
hh{2}=plot(x2(:,1), x2(:,2), '*' );
legend('Class 1','Class 2');
xl = get(gca,'xlim');
yl = get(gca,'ylim');

%% compute a separating hyperplane with SVM
% First, we use CVX to get a reference solution

hinge = @(x) sum(max(0,1-x));
lambda_1 = 10;
lambda_2 = 4;

if exist( 'cvx_begin','file')
    
% -- Problem 1: standard SVM in primal form
PROBLEM     = 1;
cvx_begin
    cvx_quiet true
    cvx_precision best
    variables a(d) b(1)
    minimize hinge( labels.*( X*a - b ) ) + lambda_1*norm(a,2)
cvx_end
SLOPE{PROBLEM} = a;
INTERCEPT{PROBLEM} = b;

% -- Problem 2: "sparse" SVM (use l1 norm as penalty)
PROBLEM     = 2;
cvx_begin
    cvx_quiet true
    cvx_precision best
    variables a(d) b(1)
    minimize hinge( labels.*( X*a - b ) ) + lambda_2*norm(a,1)
cvx_end
SLOPE{PROBLEM} = a;
INTERCEPT{PROBLEM} = b;

% An equivalent way to solve via method 2:
% X_aug = [diag(labels)*X, -labels ]; % include the "b" variable
% cvx_begin
%     variables a(d+1)
%     minimize hinge( X_aug*a ) + lambda_2*norm(a(1:2),1)
% cvx_end

else
    % load the pre-computed reference solutions
    lambda_1 = 10;
    lambda_2 = 4;
    SLOPE    = { [  -1.084604434515675;   0.783281331181009]; ...
        [  -2.391008972722243; 0] };
    INTERCEPT = {   [0.75708813868169] ; [0.260615633092470] };
end

%% plot the separating hyper-planes
for PROBLEM = 1:length(SLOPE)
    a = SLOPE{PROBLEM}; b = INTERCEPT{PROBLEM};
    
    if abs(a(2)/a(1)) < 1e-10
        % vertical line:
        hh{PROBLEM+2}=line( [1,1]*b/a(1), [-.3,2] );
    else
        grid = linspace(-.5,1,100);
        hh{PROBLEM+2}=plot( grid, (b-a(1)*grid)/a(2) );
    end
end
legend([hh{:}],'Class 1','Class2','SVM','sparse SVM');
xlim(xl); ylim(yl);

%% Solve Problem 2 in TFOCS
PROBLEM = 2;
linearF = diag(labels)*[ X, -ones(n,1) ];
objF    = prox_l1(lambda_2*[1,1,0]'); 
% objF    = prox_l1(lambda_2);
prox    = prox_hingeDual(1,1,-1); % but use -x since we want polar cone, not dual cone

mu      = 1e-2;
opts    = [];
opts.maxIts     = 1500;
opts.continuation = false;
opts.stopCrit   = 4;
opts.tol        = 1e-12;
opts.errFcn     = @(f,d,x) norm( x - [SLOPE{PROBLEM};INTERCEPT{PROBLEM}] );
x0              = zeros(d+1,1); % i.e. 3 for 2D SVM
y0              = zeros(n,1);
[ak,out,optsOut] = tfocs_SCD( objF,linearF, prox, mu,x0,y0,opts); 
% an alternative way to call it:
% [ak,out,optsOut] = tfocs_SCD( objF,{linearF,[]}, prox, mu,x0,y0,opts);

%% Solve Problem 2 in TFOCS a different way
% We dualize the l1 term now
PROBLEM = 2;
prox2           = { prox, proj_linf(lambda_2) };
linearF2        = diag( [ones(d,1);0] );
opts.errFcn     = @(f,d,x) norm( x - [SLOPE{PROBLEM};INTERCEPT{PROBLEM}] );
[ak,out,optsOut] = tfocs_SCD([],{linearF,[];linearF2,[]}, prox2, mu,[],[],opts);


%% Solve Problem 1 in TFOCS
% Keep l1 term in primal; this is an "experimental" feature
%   since the l1 proximity operator is not exactly in closed form
%   (it relies on a 1D linesearch; this should be very fast, but 
%    it could have numerical issues for very high accuract solutions)
PROBLEM = 1;
objF    = prox_l2(lambda_1*[1,1,0]'); 
opts.errFcn     = @(f,d,x) norm( x - [SLOPE{PROBLEM};INTERCEPT{PROBLEM}] );
% opts.tol        = 1e-16;
opts.continuation = true;
mu2             = 10*mu;
[ak,out,optsOut] = tfocs_SCD( objF,linearF, prox, mu2,[],[],opts); 

%% Solve Problem 1 in TFOCS a different way
% Dualize the l2 term
PROBLEM = 1;
prox2           = { prox, proj_l2(lambda_1) };
linearF2        = diag( [ones(d,1);0] );
opts.errFcn     = @(f,d,x) norm( x - [SLOPE{PROBLEM};INTERCEPT{PROBLEM}] );
opts.tol        = 1e-15;
opts.continuation = false;
[ak,out,optsOut] = tfocs_SCD([],{linearF,[];linearF2,[]}, prox2, mu,[],[],opts);




%%
% TFOCS v1.3 by Stephen Becker, Emmanuel Candes, and Michael Grant.
% Copyright 2013 California Institute of Technology and CVX Research.
% See the file LICENSE for full license information.
