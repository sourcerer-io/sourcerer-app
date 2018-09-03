%% Projection onto the intersection of two sets 
% Our goal is to find a point in the intersection of two convex sets C1 and C2.
% A similar goal is to find the projection of an arbitrary point onto the 
% intersection (or if the intersection is empty, find the point(s) in C1
% that are as close as possible to C2). In this demo, the intersection
% of C1 and C2 is a singleton, so the concepts are the same.
%
% We assume that we know how to project on the sets C1 and C2 individually,
% but not onto C1 intersect C2.
%
% The basic algorithm to solve this problem is the alternating projection method,
% first studied by John von Neumann for the case where C1 and C2 are affine
% spaces. This algorithm can be extended to arbitrary convex sets, although
% you may not converge to the *projection* of the original point.
%
% This algorithm is very simple: starting at some point y, and with x <-- y,
% we update
%   x <-- Proj_{C1}( Proj_{C2}( x ) )
% where Proj_{C1} is the projector onto the set C1.
%
% Better methods (which actually give you the projection of y onto the intersection)
% are based on Dykstra's algorithm (not to be confused with the Dijkstra algorithm
% described here: http://en.wikipedia.org/wiki/Dijkstra%27s_algorithm ).
%
% Dykstra's algorithm also uses only Proj_{C1} and Proj_{C2}, but with a few
% intermediate steps. For an overview, see the 2011 book by Raydan:
% http://www.amazon.com/Alternating-Projection-Methods-Fundamentals-Algorithms/dp/1611971934
%
% Another overview of both alternating projection and Dykstra are in the book chapter
% "Proximal splitting methods in signal processing" by P. L. Combettes and J.-C. Pesquet, 
% in the book 'Fixed-Point Algorithms for Inverse Problems in Science and Engineering',
% (ed.: H. H. Bauschke, R. S. Burachik, P. L. Combettes, V. Elser, D. R. Luke, and 
% H. Wolkowicz, Editors), pp. 185-212. Springer, New York, 2011.
% The chapter can be downloaded at http://www.ann.jussieu.fr/~plc/prox.pdf
%
% The purpose of this demo is to show the above two methods, and also
% how to formulate this with TFOCS. The advantage of solving this with TFOCS
% is that we can use an accelerated solver (Nesterov-style) and use large
% step-sizes and line search (whereas Dykstra has no step-size parameter).
% In the first example, it is especially apparent that TFOCS avoids
% the slow convergence that both the alternating projection and Dykstra
% algorithms suffer from. In the second example, the performance
% of alternating projections and TFOCS are quite similar.

%% Mathematical formulation
% For a given point y, and two convex sets C1 and C2, we wish to find
% the closest point x to y, such that x is in both C1 and C2. We write this
% as:
%
% $$ \textrm{minimize}_{x\in C_1 \cap C_2} \,\, \mu/2||x\textrm{--}y||_2^2 $$
%
% The parameter $\mu > 0$ is arbitrary and does not affect the answer.
%
% This fits naturally into the TFOCS formulation since the primal
% problem is already strongly convex.



%% Demo with two polygon sets in 2D that intersect at (0,0)
% Set the dimension to 2
N = 2;  % 2D is best for visualization

%%
% Define some 2D polygons

mx = 1;
x1a = [1;.1];
x1b = [1;.2];
xx1 = [0,x1a(1),2*mx,x1b(1)];
yy1 = [0,x1a(2),2*mx,x1b(2)];


x2a = [1;.3];
x2b = [1;.35];
xx2 = [0,x2a(1),2*mx,x2b(1)];
yy2 = [0,x2a(2),2*mx,x2b(2)];

%%
% The solution is at x = (0,0), so our error function is simple

err = @(x) norm(x);
%%
% plot the regions

figure
red = [255,153,153]/255;
blue = [204,204,255]/255;
fill( xx1, yy1,red); 
hold on
fill( xx2, yy2,blue); 

xlim( [0,mx] ); ylim( [0,.5*mx] ); 
axis equal
text(.5,.07,'set C1');
text(.5,.22,'set C2');

%%
% Make some operators that will be used with TFOCS

addpath ~/Dropbox/TFOCS/  % modify this to wherever it is installed on your computer
op1     = project2DCone(x1a, x1b );
op2     = project2DCone(x2a, x2b );

offset1 = 0;
offset2 = 0;
op1_d   = prox_dualize(op1);
op2_d   = prox_dualize(op2);

% and some simpler operators that we will use with alternating projections
%   and with Dykstra
proj1   = @(x) callandmap( op1, 2, x, 1); % gamma is irrelevant
proj2   = @(x) callandmap( op2, 2, x, 1 ); % gamma is irrelevant

% for all methods, we need to specify a starting point

x0      = [1; 1/4];


%% solve in TFOCS
% We can pick any mu and should get the same result, although due to 
% some scaling issues in stopping criteria, it does have a small effect.
mu = 1e-6; 

opts    = struct('debug',false,'printEvery',20,'maxIts',200);
opts.errFcn{1}  = @(f,d,x) err(x);
opts.errFcn{2}  = @(f,d,x) recordPoints(x);
recordPoints(); % zero-out counter. We use this to plot the points later

opts.tol        = 1e-15;

affineOperator  = {eye(N),offset1;eye(N),offset2};
dualProx        = {op1_d,op2_d};
% Solve in TFOCS:
[x,out,optsOut] = tfocs_SCD( [], affineOperator, dualProx , mu, x0, [], opts );

% Record the path:
path    = recordPoints();
path    = [x0,path];

figure
subplot(1,2,1);
fill( xx1, yy1,red); 
hold on
fill( xx2, yy2,blue); 
xlim( [0,mx] ); ylim( [0,.5*mx] ); 
text(.5,.07,'set C1');
text(.5,.22,'set C2');
plot( path(1,:), path(2,:),'ko-','linewidth',2 )
title('Path for TFOCS solving the intersection of 2 polygons');

subplot(1,2,2);
semilogy( out.err(:,1) ,'o-'); xlabel('iterations'); ylabel('error');
title('Error for TFOCS method');
set(gcf, 'Position', [400 200 800 400]);
%% solve via alternating projection method
maxIts  = 500;
x       = x0;
path    = [x0];
errHist = [];
for k = 1:maxIts
    % basic alternating projection method:
    x   = proj1(x);
    path= [path, x];
    x   = proj2(x);
    path= [path, x];
    errHist     = [ errHist; err(x) ];
    if ~mod(k,50)
        fprintf('Iter %4d, error is %.2e\n', k, errHist(end) );
    end
end
figure
subplot(1,2,1);
fill( xx1, yy1,red); 
hold on
fill( xx2, yy2,blue); 
xlim( [0,mx] ); ylim( [0,.5*mx] ); 
text(.5,.07,'set C1');
text(.5,.22,'set C2');
plot( path(1,:), path(2,:),'ko-','linewidth',1 )
title('Path for alternating projection method solving the intersection of 2 polygons');

subplot(1,2,2);
semilogy( errHist, 'o-' ); xlabel('iterations'); ylabel('error');
errHist_1 = errHist;
title('Error for alternating projection method');
set(gcf, 'Position', [400 200 800 400]);
%% solve via Dykstra's algorithm

maxIts  = 500;
x       = x0;
[p,q]   = deal( 0*x0 );
p       = -.25*[1;1];
path    = [x0];
errHist = [];
for k = 1:maxIts
    % If x + p is feasible, the y = (x+p), so p=x+p-y = 0.
    y   = proj1( x + p );
    p   = x + p - y;
    x   = proj2( y + q );
    q   = y + q - x;
    path = [path,y,x];
    errHist     = [ errHist; err(x) ];
    if ~mod(k,50)
        fprintf('Iter %4d, error is %.2e\n', k, errHist(end) );
    end
end
figure
subplot(1,2,1);
fill( xx1, yy1,red); 
hold on
fill( xx2, yy2,blue); 
xlim( [0,mx] ); ylim( [0,.5*mx] ); 
text(.5,.07,'set C1');
text(.5,.22,'set C2');
plot( path(1,:), path(2,:),'ko-' )
title('Path for Dykstra''s algo solving the intersection of 2 polygons');

subplot(1,2,2);
semilogy( errHist, 'o-' ); xlabel('iterations'); ylabel('error');
title('Error for Dykstra''s method');
set(gcf, 'Position', [400 200 800 400]);

%%
% With Dykstra's algo (and alternating projections), we get
% very slow convergence, because of the very low angle between the
% two sets. Here is a zoom in on the graph of the iterates:
figure
fill( xx1, yy1,red); 
hold on
fill( xx2, yy2,blue); 
xlim( [0,mx] ); ylim( [0,.5*mx] ); 
text(.5,.07,'set C1');
text(.5,.22,'set C2');
plot( path(1,:), path(2,:),'ko-' )
title('Path for Dykstra''s algo solving the intersection of 2 polygons (zoom)');
xlim( [.25,.4] );
ylim( [.058,.1])
%% Plot all the errors together
figure
semilogy( out.err(:,1),'-' ,'linewidth',3);
hold all
semilogy( errHist_1,'-','linewidth',3);
semilogy( errHist,'--','linewidth',3);
legend('TFOCS','Alternating projection','Dykstra');
xlabel('iteration'); ylabel('error');
%% Demo with two circles that intersect at (0,0)
center1     = [0;.5];
radius1     = .5;
center2     = -center1;
radius2     = radius1;

figure
rectangle('Position',[-radius1,0,2*radius1,2*radius1],'Curvature',[1,1],'FaceColor',red)
rectangle('Position',[-radius1,-2*radius2,2*radius1,2*radius1],'Curvature',[1,1],'FaceColor',blue)
axis equal
hold on
text(0,.5,'set C1');
text(0,-.5,'set C2');


offset1     = center1;
offset2     = center2;

op1_d       = prox_l2(radius1);
op2_d       = prox_l2(radius2);
x0          = [1; .2];

% and some simpler operators that we will use with alternating projections
%   and with Dykstra
proj1   = @(x) radius1*(x-center1)/norm(x-center1) + center1;
proj2   = @(x) radius2*(x-center2)/norm(x-center2) + center2;
%% solve in TFOCS
opts.maxIts     = 300;
affineOperator  = {eye(N),offset1;eye(N),offset2};
dualProx        = {op1_d,op2_d};
% Solve in TFOCS:
[x,out,optsOut] = tfocs_SCD( [], affineOperator, dualProx , mu, x0, [], opts );

% Record the path:
path    = recordPoints();
path    = [x0,path];
% Plot:
figure
subplot(1,3,1);
rectangle('Position',[-radius1,0,2*radius1,2*radius1],'Curvature',[1,1],'FaceColor',red)
rectangle('Position',[-radius1,-2*radius2,2*radius1,2*radius1],'Curvature',[1,1],'FaceColor',blue)
hold on
text(0,.5,'set C1');
text(0,-.5,'set C2');
plot( path(1,:), path(2,:),'ko-','linewidth',2 )
title('Path for TFOCS solving the intersection of 2 circles');

subplot(1,3,2);
rectangle('Position',[-radius1,0,2*radius1,2*radius1],'Curvature',[1,1],'FaceColor',red)
rectangle('Position',[-radius1,-2*radius2,2*radius1,2*radius1],'Curvature',[1,1],'FaceColor',blue)
hold on
plot( path(1,:), path(2,:),'ko-','linewidth',2 )
xlim([0,.15]);
ylim([-.1,.1]);
title('(zoom)');

subplot(1,3,3);
semilogy( out.err,'o-')
title('Error of iterates for TFOCS method');
set(gcf, 'Position', [400 200 800 400]);
%% solve via alternating projection method
maxIts  = 300;
x       = x0;
path    = [x0];
errHist = [];
for k = 1:maxIts
    % basic alternating projection method:
    x   = proj1(x);
    path= [path, x];
    x   = proj2(x);
    path= [path, x];
    errHist     = [ errHist; err(x) ];
    if ~mod(k,50)
        fprintf('Iter %4d, error is %.2e\n', k, errHist(end) );
    end
end
figure
subplot(1,3,1);
rectangle('Position',[-radius1,0,2*radius1,2*radius1],'Curvature',[1,1],'FaceColor',red)
rectangle('Position',[-radius1,-2*radius2,2*radius1,2*radius1],'Curvature',[1,1],'FaceColor',blue)
hold on
text(0,.5,'set C1');
text(0,-.5,'set C2');
plot( path(1,:), path(2,:),'ko-' )
title('Path for alternating projection method solving the intersection of 2 circles');

subplot(1,3,2);
rectangle('Position',[-radius1,0,2*radius1,2*radius1],'Curvature',[1,1],'FaceColor',red)
rectangle('Position',[-radius1,-2*radius2,2*radius1,2*radius1],'Curvature',[1,1],'FaceColor',blue)
hold on
plot( path(1,:), path(2,:),'ko-','linewidth',2 )
xlim([0,.15]);
ylim([-.1,.1]);
title('(zoom)');

subplot(1,3,3);
semilogy( errHist,'o-')
errHist_1 = errHist;
title('Error of iterates for alternating projection method');
set(gcf, 'Position', [400 200 800 400]);
%% solve via Dykstra's algorithm

maxIts  = 300;
x       = x0;
[p,q]   = deal( 0*x0 );
path    = [x0];
errHist = [];
for k = 1:maxIts
    % If x + p is feasible, the y = (x+p), so p=x+p-y = 0.
    y   = proj1( x + p );
    p   = x + p - y;
    x   = proj2( y + q );
    q   = y + q - x;
    path = [path,y];
    path = [path,x];
    errHist     = [ errHist; err(x) ];
    if ~mod(k,50)
        fprintf('Iter %4d, error is %.2e\n', k, errHist(end) );
    end
end
figure
subplot(1,3,1);
rectangle('Position',[-radius1,0,2*radius1,2*radius1],'Curvature',[1,1],'FaceColor',red)
rectangle('Position',[-radius1,-2*radius2,2*radius1,2*radius1],'Curvature',[1,1],'FaceColor',blue)
hold on
text(0,.5,'set C1');
text(0,-.5,'set C2');
plot( path(1,:), path(2,:),'ko-' )
title('Path for Dykstra''s algo solving the intersection of 2 circles');

subplot(1,3,2);
rectangle('Position',[-radius1,0,2*radius1,2*radius1],'Curvature',[1,1],'FaceColor',red)
rectangle('Position',[-radius1,-2*radius2,2*radius1,2*radius1],'Curvature',[1,1],'FaceColor',blue)
hold on
plot( path(1,:), path(2,:),'ko-','linewidth',2 )
xlim([0,.15]);
ylim([-.1,.1]);
title('(zoom)');

subplot(1,3,3);
semilogy( errHist,'o-')
title('Error of iterates for Dykstra''s algo');
set(gcf, 'Position', [400 200 800 400]);

%% Plot all the errors together
figure
semilogy( out.err(:,1),'-' ,'linewidth',3);
hold all
semilogy( errHist_1,'-','linewidth',3);
semilogy( errHist,'--','linewidth',3);
legend('TFOCS','Alternating projection','Dykstra');
xlabel('iteration'); ylabel('error');

% TFOCS v1.3 by Stephen Becker, Emmanuel Candes, and Michael Grant.
% Copyright 2013 California Institute of Technology and CVX Research.
% See the file LICENSE for full license information.

