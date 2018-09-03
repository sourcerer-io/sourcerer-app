% Figure 8.16: Quadratic placement problem
% Section 8.7.3, Boyd & Vandenberghe "Convex Optimization"
% Original by Lieven Vandenberghe
% Adapted for CVX by Joelle Skaf - 10/24/05
% (a figure is generated)
%
% Placement problem with 6 free points, 8 fixed points and 27 links.
% The coordinates of the free points minimize the sum of the squares of
% Euclidean lengths of the links, i.e.
%           minimize    sum_{i<j) h(||x_i - x_j||)
% where h(z) = z^2.

linewidth = 1;      % in points;  width of dotted lines
markersize = 5;    % in points;  marker size

% Input data
fixed = [ 1   1  -1 -1    1   -1  -0.2  0.1; % coordinates of fixed points
          1  -1  -1  1 -0.5 -0.2    -1    1]';
M = size(fixed,1);  % number of fixed points
N = 6;              % number of free points

% first N columns of A correspond to free points,
% last M columns correspond to fixed points

A = [ 1  0  0 -1  0  0    0  0  0  0  0  0  0  0
      1  0 -1  0  0  0    0  0  0  0  0  0  0  0
      1  0  0  0 -1  0    0  0  0  0  0  0  0  0
      1  0  0  0  0  0   -1  0  0  0  0  0  0  0
      1  0  0  0  0  0    0 -1  0  0  0  0  0  0
      1  0  0  0  0  0    0  0  0  0 -1  0  0  0
      1  0  0  0  0  0    0  0  0  0  0  0  0 -1
      0  1 -1  0  0  0    0  0  0  0  0  0  0  0
      0  1  0 -1  0  0    0  0  0  0  0  0  0  0
      0  1  0  0  0 -1    0  0  0  0  0  0  0  0
      0  1  0  0  0  0    0 -1  0  0  0  0  0  0
      0  1  0  0  0  0    0  0 -1  0  0  0  0  0
      0  1  0  0  0  0    0  0  0  0  0  0 -1  0
      0  0  1 -1  0  0    0  0  0  0  0  0  0  0
      0  0  1  0  0  0    0 -1  0  0  0  0  0  0
      0  0  1  0  0  0    0  0  0  0 -1  0  0  0
      0  0  0  1 -1  0    0  0  0  0  0  0  0  0
      0  0  0  1  0  0    0  0 -1  0  0  0  0  0
      0  0  0  1  0  0    0  0  0 -1  0  0  0  0
      0  0  0  1  0  0    0  0  0  0  0 -1  0  0
      0  0  0  1  0 -1    0  0  0  0  0 -1  0  0        % error in data!!!
      0  0  0  0  1 -1    0  0  0  0  0  0  0  0
      0  0  0  0  1  0   -1  0  0  0  0  0  0  0
      0  0  0  0  1  0    0  0  0 -1  0  0  0  0
      0  0  0  0  1  0    0  0  0  0  0  0  0 -1
      0  0  0  0  0  1    0  0 -1  0  0  0  0  0
      0  0  0  0  0  1    0  0  0  0 -1  0  0  0 ];
nolinks = size(A,1);    % number of links

fprintf(1,'Computing the optimal locations of the 6 free points...');

cvx_begin
    variable x(N+M,2)
    minimize ( sum(square_pos(norms( A*x,2,2 ))))
    x(N+[1:M],:) == fixed;
cvx_end

fprintf(1,'Done! \n');

% Plots
free_sum = x(1:N,:);
figure(1);
dots = plot(free_sum(:,1), free_sum(:,2), 'or', fixed(:,1), fixed(:,2), 'bs');
set(dots(1),'MarkerFaceColor','red');
hold on
legend('Free points','Fixed points','Location','Best');
for i=1:nolinks
  ind = find(A(i,:));
  line2 = plot(x(ind,1), x(ind,2), ':k');
  hold on
  set(line2,'LineWidth',linewidth);
end
axis([-1.1 1.1 -1.1 1.1]) ;
axis equal;
title('Quadratic placement problem');
% print -deps placement-quadr.eps

figure(2)
all = [free_sum; fixed];
bins = 0.05:0.1:1.95;
lengths = sqrt(sum((A*all).^2')');
[N2,hist2] = hist(lengths,bins);
bar(hist2,N2);
hold on;
xx = linspace(0,2,1000); yy = (4/1.5^2)*xx.^2;
plot(xx,yy,'--');
axis([0 1.5 0 4.5]);
hold on
plot([0 2], [0 0 ], 'k-');
title('Distribution of the 27 link lengths');
% print -deps placement-quadr-hist.eps

