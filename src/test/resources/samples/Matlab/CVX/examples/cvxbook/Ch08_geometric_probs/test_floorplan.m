% Example 8.7: Floorplan generation test script
% Section 8.8.1/2, Boyd & Vandenberghe "Convex Optimization"
% Joelle Skaf 12/04/05
%
% Rectangles aligned with the axes need to be place in the smallest
% possible bounding box. No overlap is allowed. Each rectangle to be placed
% can be reconfigured, within some limits.
% In the current problem, 60 rectangles are to be place. We are given 2
% acyclic graphs H and V (for horizontal and vertical) that specify the
% relative positioning constraints of those rectangles.
% We are also given minimal areas for the rectangles and aspect ratio
% constraints

% input data
load data_floorplan_60;
rho = 1;
Amin = 100*ones(1,n);

[W, H, w, h, x, y] = floorplan(adj_H, adj_V, rho, Amin,ones(60,1)*0.5,ones(60,1)*2);
fill([0; W; W; 0],[0;0;H;H],[1 1 1]);           % bounding box
hold on
for i=1:n
    fill([x(i); x(i)+w(i); x(i)+w(i); x(i)],[y(i);y(i);y(i)+h(i);y(i)+h(i)],0.90*[1 1 1]);
    hold on;
    text(x(i)+w(i)/2, y(i)+h(i)/2,[int2str(i)]);
end
axis([0 W 0 H]);
axis equal; axis off;
