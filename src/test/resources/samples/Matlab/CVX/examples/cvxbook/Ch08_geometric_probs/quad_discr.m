% Quadratic discrimination (separating ellipsoid)
% Section 8.6.2, Boyd & Vandenberghe "Convex Optimization"
% Original by Lieven Vandenberghe
% Adapted for CVX by Joelle Skaf - 10/16/05
% (a figure is generated)
%
% The goal is to find an ellipsoid that contains all the points
% x_1,...,x_N but none of the points y_1,...,y_M. The equation of the
% ellipsoidal surface is: z'*P*z + q'*z + r =0
% P, q and r can be obtained by solving the SDP feasibility problem:
%           minimize    0
%               s.t.    x_i'*P*x_i + q'*x_i + r >=  1   for i = 1,...,N
%                       y_i'*P*y_i + q'*y_i + r <= -1   for i = 1,...,M
%                       P <= -I

% data generation
n = 2;
rand('state',0);  randn('state',0);
N=50;
X = randn(2,N);  X = X*diag(0.99*rand(1,N)./sqrt(sum(X.^2)));
Y = randn(2,N);  Y = Y*diag((1.02+rand(1,N))./sqrt(sum(Y.^2)));
T = [1 -1; 2 1];  X = T*X;  Y = T*Y;

% Solution via CVX
fprintf(1,'Find the optimal ellipsoid that seperates the 2 classes...');

cvx_begin sdp
    variable P(n,n) symmetric
    variables q(n) r(1)
    P <= -eye(n);
    sum((X'*P).*X',2) + X'*q + r >= +1;
    sum((Y'*P).*Y',2) + Y'*q + r <= -1;
cvx_end

fprintf(1,'Done! \n');

% Displaying results
r = -r; P = -P; q = -q;
c = 0.25*q'*inv(P)*q - r;
xc = -0.5*inv(P)*q;
nopts = 1000;
angles = linspace(0,2*pi,nopts);
ell = inv(sqrtm(P/c))*[cos(angles); sin(angles)] + repmat(xc,1,nopts);
graph=plot(X(1,:),X(2,:),'o', Y(1,:), Y(2,:),'o', ell(1,:), ell(2,:),'-');
set(graph(2),'MarkerFaceColor',[0 0.5 0]);
set(gca,'XTick',[]); set(gca,'YTick',[]);
title('Quadratic discrimination');
% print -deps ellips.eps
