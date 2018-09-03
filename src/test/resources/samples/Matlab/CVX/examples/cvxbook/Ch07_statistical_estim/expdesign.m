% Section 7.5.2: Experiment design
% Boyd & Vandenberghe, "Convex Optimization"
% Original version by Lieven Vandenberghe
% Updated for CVX by Almir Mutapcic - Jan 2006
% (a figure is generated)
%
% This is an example of D-optimal, A-optimal, and E-optimal
% experiment designs.

% problem data
m = 10;
angles1 = linspace(3*pi/4,pi,m);
angles2 = linspace(0,-pi/2,m);

% sensor positions
V = [3.0*[cos(angles1); sin(angles1)], ...
     1.5*[cos(angles2); sin(angles2)]];
p = size(V,2);
n = 2;
noangles = 5000;

% D-optimal design
%
%      maximize    log det V*diag(lambda)*V'
%      subject to  sum(lambda)=1,  lambda >=0
%

% setup the problem and solve it
cvx_begin
  variable lambda(p)
  maximize ( det_rootn( V*diag(lambda)*V' ) )
  subject to
    sum(lambda) == 1;
    lambda >= 0;
cvx_end
lambdaD = lambda; % save the solution for confidence ellipsoids

% plot results
figure(1)
% draw ellipsoid v'*W*v <= 2
W = inv(V*diag(lambda)*V');
angles = linspace(0,2*pi,noangles);
R = chol(W);  % W = R'*R
ellipsoid = sqrt(2)*(R\[cos(angles); sin(angles)]);
d = plot(ellipsoid(1,:), ellipsoid(2,:), '--', 0,0,'+');
set(d, 'Color', [0 0.5 0]); set(d(2),'MarkerFaceColor',[0 0.5 0]);
hold on;

dot=plot(V(1,:),V(2,:),'o');
ind = find(lambda > 0.001);
dots = plot(V(1,ind),V(2,ind),'o');
set(dots,'MarkerFaceColor','blue');

% print out nonzero lambda
disp('Nonzero lambda values for D design:');
for i=1:length(ind)
   text(V(1,ind(i)),V(2,ind(i)), ['l',int2str(ind(i))]);
   disp(['lambda(',int2str(ind(i)),') = ', num2str(lambda(ind(i)))]);
end;

%axis([-4.5 4.5 -4.5 4.5])
axis([-5 5 -5 5])
set(gca,'Xtick',[]);
set(gca,'Ytick',[]);
hold off, axis off
% print -deps Ddesign.eps

% A-optimal design
%
%      minimize    Trace (sum_i lambdai*vi*vi')^{-1}
%      subject to  lambda >= 0, 1'*lambda = 1
%

% SDP formulation
e = eye(2,2);
cvx_begin sdp
  variables lambda(p) u(n)
  minimize ( sum(u) )
  subject to
    for k = 1:n
      [ V*diag(lambda)*V'  e(:,k);
        e(k,:)             u(k)   ] >= 0;
    end
    sum(lambda) == 1;
    lambda >= 0;
cvx_end
lambdaA = lambda; % save the solution for confidence ellipsoids

% plot results
figure(2)
% draw ellipsoid v'*W*v <= mu
W = inv(V*diag(lambda)*V')^2;
mu = diag(V'*W*V);
mu = mean(mu(ind));
angles = linspace(0,2*pi,noangles);
R = chol(W);  % W = R'*R
ellipsoid = sqrt(mu)*(R\[cos(angles); sin(angles)]);
d = plot(ellipsoid(1,:), ellipsoid(2,:), '--',0,0,'+');
set(d, 'Color', [0 0.5 0]);
set(d(2), 'MarkerFaceColor', [0 0.5 0]);
hold on

dot = plot(V(1,:),V(2,:),'o');
ind = find(lambda > 0.001);
dots = plot(V(1,ind),V(2,ind),'o');
set(dots,'MarkerFaceColor','blue');

disp('Nonzero lambda values for A design:');
for i=1:length(ind)
   text(V(1,ind(i)),V(2,ind(i)), ['l',int2str(ind(i))]);
   disp(['lambda(',int2str(ind(i)),') = ', num2str(lambda(ind(i)))]);
end;
%axis([-4.5 4.5 -4.5 4.5])
axis([-5 5 -5 5])
set(gca,'Xtick',[]);
set(gca,'Ytick',[]);
axis off, hold off
% print -deps Adesign.eps

% E-optimal design
%
%      minimize    w
%      subject to  sum_i lambda_i*vi*vi' >= w*I
%                  lambda >= 0,  1'*lambda = 1;
%

cvx_begin sdp
  variables t lambda(p)
  maximize ( t )
  subject to
    V*diag(lambda)*V' >= t*eye(n,n);
    sum(lambda) == 1;
    lambda >= 0;
cvx_end

lambdaE = lambda; % save the solution for confidence ellipsoids

figure(3)
% draw ellipsoid v'*W*v <= mu
mu = diag(V'*W*V);
mu = mean(mu(ind));
angles = linspace(0,2*pi,noangles);
R = chol(W);  % W = R'*R
ellipsoid = sqrt(mu)*(R\[cos(angles); sin(angles)]);
d = plot(ellipsoid(1,:), ellipsoid(2,:), '--', 0, 0, '+');
set(d, 'Color', [0 0.5 0]);
set(d(2), 'MarkerFaceColor', [0 0.5 0]);
hold on

dot = plot(V(1,:),V(2,:),'o');
lambda = lambda(1:p);
ind = find(lambda > 0.001);
dots = plot(V(1,ind),V(2,ind),'o');
set(dots,'MarkerFaceColor','blue');

disp('Nonzero lambda values for E design:');
for i=1:length(ind)
   text(V(1,ind(i)),V(2,ind(i)), ['l',int2str(ind(i))]);
   disp(['lambda(',int2str(ind(i)),') = ', num2str(lambda(ind(i)))]);
end;
%axis([-4.5 4.5 -4.5 4.5])
axis([-5 5 -5 5])
set(gca,'Xtick',[]);
set(gca,'Ytick',[]);
axis off, hold off
% print -deps Edesign.eps


% confidence ellipsoids
eta = 6.2514; % chi2inv(.9,3) value (command available in stat toolbox)
% draw 90 percent confidence ellipsoid  for D design
W = V*diag(lambdaD)*V';
angles = linspace(0,2*pi,noangles);
R = chol(W);  % W = R'*R
ellipsoid = sqrt(eta)*(R\[cos(angles); sin(angles)]);

figure(4)
plot(0,0,'ok',ellipsoid(1,:), ellipsoid(2,:), '-');
text(ellipsoid(1,1100),ellipsoid(2,1100),'D');
hold on

% draw 90 percent confidence ellipsoid  for A design
W = V*diag(lambdaA)*V';
angles = linspace(0,2*pi,noangles);
R = chol(W);  % W = R'*R
ellipsoid = sqrt(eta)*(R\[cos(angles); sin(angles)]);
plot(0,0,'ok',ellipsoid(1,:), ellipsoid(2,:), '-');
text(ellipsoid(1,1),ellipsoid(2,1),'A');

% draw 90 percent confidence ellipsoid  for E design
W = V*diag(lambdaE)*V';
angles = linspace(0,2*pi,noangles);
R = chol(W);  % W = R'*R
ellipsoid = sqrt(eta)*(R\[cos(angles); sin(angles)]);
d=plot(0,0,'ok',ellipsoid(1,:), ellipsoid(2,:), '-');
set(d,'Color',[0 0.5 0]);
text(ellipsoid(1,4000),ellipsoid(2,4000),'E');

% draw 90 percent confidence ellipsoid  for uniform design
W_u = inv(V*V'/p);
R = chol(W_u);  % W = R'*R
ellipsoid_u = sqrt(eta)*(R\[cos(angles); sin(angles)]);
plot(ellipsoid_u(1,:), ellipsoid_u(2,:), '--');
text(ellipsoid_u(1),ellipsoid_u(2),'U');
set(gca,'Xtick',[]);
set(gca,'Ytick',[]);
axis off
% print -deps confidence.eps
hold off
