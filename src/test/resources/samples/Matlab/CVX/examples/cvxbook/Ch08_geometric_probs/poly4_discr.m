% Polynomial discrimination
% Section 8.6.2, Boyd & Vandenberghe "Convex Optimization"
% Original by Lieven Vandenberghe
% Adapted for CVX by Joelle Skaf - 10/23/05
% (a figure is generated)
%
% The goal is to find the polynomial of degree 4 on R^n that separates
% two sets of points {x_1,...,x_N} and {y_1,...,y_N}. We are trying to find
% the coefficients of an order-4-polynomial P(x) that would satisfy:
%           minimize    t
%               s.t.    P(x_i) <= t  for i = 1,...,N
%                       P(y_i) >= t   for i = 1,...,M

% Data generation
rand('state',0);
N = 100;
M = 120;

% The points X lie within a circle of radius 0.9, with a wedge of points
% near [1.1,0] removed. The points Y lie outside a circle of radius 1.1,
% with a wedge of points near [1.1,0] added. The wedges are precisely what
% makes the separation difficult and interesting.
X = 2 * rand(2,N) - 1;
X = X * diag(0.9*rand(1,N)./sqrt(sum(X.^2)));
Y = 2 * rand(2,M) - 1;
Y = Y * diag((1.1+rand(1,M))./sqrt(sum(Y.^2)));
d = sqrt(sum((X-[1.1;0]*ones(1,N)).^2));
Y = [ Y, X(:,d<0.9) ];
X = X(:,d>1);
N = size(X,2);
M = size(Y,2);

% Construct Vandermonde-style monomial matrices
p1   = [0,0,1,0,1,2,0,1,2,3,0,1,2,3,4]';
p2   = [0,1,1,2,2,2,3,3,3,3,4,4,4,4,4]'-p1;
np   = length(p1);
op   = ones(np,1);
monX = X(op,:) .^ p1(:,ones(1,N)) .* X(2*op,:) .^ p2(:,ones(1,N));
monY = Y(op,:) .^ p1(:,ones(1,M)) .* Y(2*op,:) .^ p2(:,ones(1,M));

% Solution via CVX
fprintf(1,'Finding the optimal polynomial of order 4 that separates the 2 classes...');

cvx_begin
    variables a(np) t(1)
    minimize ( t )
    a'*monX <= t;
    a'*monY >= -t;
    % For normalization purposes only
    norm(a) <= 1;
cvx_end

fprintf(1,'Done! \n');

% Displaying results
nopts = 2000;
angles = linspace(0,2*pi,nopts);
cont = zeros(2,nopts);
for i=1:nopts
   v = [cos(angles(i)); sin(angles(i))];
   l = 0;  u = 1;
   while ( u - l > 1e-3 )
      s = (u+l)/2;
      x = s * v;
      if a' * ( x(op,:) .^ p1 .* x(2*op) .^ p2 ) > 0, 
          u = s; 
      else
          l = s;
      end
   end;
   s = (u+l)/2;
   cont(:,i) = s*v;
end;

graph = plot(X(1,:),X(2,:),'o', Y(1,:), Y(2,:),'o', cont(1,:), cont(2,:), '-');
set(graph(2),'MarkerFaceColor',[0 0.5 0]);
title('Optimal order-4 polynomial that separates the 2 classes')
% print -deps min-deg-discr.eps

%%%% Dual infeasible ?????
