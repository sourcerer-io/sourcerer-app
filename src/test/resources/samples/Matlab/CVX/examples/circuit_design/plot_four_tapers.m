function plot_four_tapers(w1,w2,w3,w4)
% Plots four different taper desings on a single graph.
% Inputs:
%      [w1 w2 w3 w4]: an array of taper widths
%
% Original code written by Lieven Vandenberghe.
% Updated by Almir Mutapcic 12/2005

n = size(w1,1);
colormap(gray);
width = zeros(2*n,4);
width([1:2:2*n-1],:) =  [w1 w2 w3 w4];
width([2:2:2*n],:)   =  [w1 w2 w3 w4];
x = zeros(2*n,1);
x([1:2:2*n-1],:) = [0:n-1]';
x([2:2:2*n],:)   = [1:n]';

% first solution
subplot(411)
hold off
plot([x;flipud(x);0], [0.5*(width(1,1)-width(:,1)); ...
    flipud(0.5*(width(1,1)+width(:,1))); 0]);
hold on;
fill([x;flipud(x);0]', [0.5*(width(1,1)-width(:,1)); ...
  flipud(0.5*(width(1,1)+width(:,1))); 0]', 0.9*ones(size([x;x;0]'))); 
caxis([-1,1]);
plot([x;flipud(x);0], [0.5*(width(1,1)-width(:,1)); ...
    flipud(0.5*(width(1,1)+width(:,1))); 0]);
ylabel('width');

% second solution
subplot(412)
hold off
plot([x;flipud(x);0], [0.5*(width(1,2)-width(:,2)); ...
    flipud(0.5*(width(1,2)+width(:,2))); 0]);
hold on;
fill([x;flipud(x);0]', [0.5*(width(1,2)-width(:,2)); ...
   flipud(0.5*(width(1,2)+width(:,2))); 0]', 0.9*ones(size([x;x;0]'))); 
caxis([-1,1]);
plot([x;flipud(x);0], [0.5*(width(1,2)-width(:,2)); ...
    flipud(0.5*(width(1,2)+width(:,2))); 0]);
ylabel('width');

% third solution
subplot(413)
hold off
plot([x;flipud(x);0], [0.5*(width(1,3)-width(:,3)); ...
    flipud(0.5*(width(1,3)+width(:,3))); 0]);
hold on;
fill([x;flipud(x);0]', [0.5*(width(1,3)-width(:,3)); ...
  flipud(0.5*(width(1,3)+width(:,3))); 0]', 0.9*ones(size([x;x;0]'))); 
caxis([-1,1]);
plot([x;flipud(x);0], [0.5*(width(1,3)-width(:,3)); ...
    flipud(0.5*(width(1,3)+width(:,3))); 0]);
ylabel('width');

% fourth solution
subplot(414)
hold off
plot([x;flipud(x);0], [0.5*(width(1,4)-width(:,4)); ...
    flipud(0.5*(width(1,4)+width(:,4))); 0]);
hold on;
fill([x;flipud(x);0]', [0.5*(width(1,4)-width(:,4)); ...
   flipud(0.5*(width(1,4)+width(:,4))); 0]', 0.9*ones(size([x;x;0]'))); 
caxis([-1,1]);
plot([x;flipud(x);0], [0.5*(width(1,4)-width(:,4)); ...
    flipud(0.5*(width(1,4)+width(:,4))); 0]);
ylabel('width');
xlabel('segment');
