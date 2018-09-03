function plotgraph(A,xy,weights)
% Plots a graph with each edge width proportional to its weight.
%
% Edges with positive weights are drawn in blue; negative weights in red.
%
% Input parameters:
% A       --- incidence matrix of the graph (size is n x m)
%             (n is the number of nodes and m is the number of edges)
% xy      --- horizontal and vertical positions of the nodes (n x 2 matrix)
% weights --- m vector giving edge weights
%
% Original by Lin Xiao
% Modified by Almir Mutapcic

% graph size
[n,m]= size(A);

% set the graph scale and normalize the coordinates to lay in [-1,1] square
R = max(max(abs(xy))); % maximum abs value of the xy coordinates
x = xy(:,1)/R; y = xy(:,2)/R;

% normalize weight vector to range between +1 and -1
weights = weights/max(abs(weights));

% internal parameters (tune these parameters to make the plot look pretty)
% (note that the graph coordinates and the weights have been rescaled
% to a common unity scale)
%rNode = 0.005;     % radius of the node circles
rNode = 0;          % set the node radius to zero if you do not want the nodes
wNode = 2;          % line width of the node circles
PWColor = [0 0 1];  % color of the edges with positive weights
NWColor = [1 0 0];  % color of the edges with negative weights
Wmin = 0.0001;      % minimum weight value for which we draw an edge
max_width = 0.05;   % drawn width of edge with maximum absolute weight

% first draw the edges with patch widths proportional to the weights
for i=1:m
  if ( abs(weights(i)) > Wmin )
    Isrc = find( sign(weights(i))*A(:,i)>0 );
    Idst = find( sign(weights(i))*A(:,i)<0 );
  else
    Isrc = find( A(:,i)>0 );
    Idst = find( A(:,i)<0 );
  end

  % obtain edge patch coordinates
  xdelta = x(Idst) - x(Isrc); ydelta = y(Idst) - y(Isrc);
  RotAgl = atan2( ydelta, xdelta );
  xstart = x(Isrc) + rNode*cos(RotAgl); ystart = y(Isrc) + rNode*sin(RotAgl);
  xend   = x(Idst) - rNode*cos(RotAgl); yend   = y(Idst) - rNode*sin(RotAgl);
  L = sqrt( xdelta^2 + ydelta^2 ) - 2*rNode;

  if ( weights(i) > Wmin )
    W = abs(weights(i))*max_width;
    drawedge(xstart, ystart, RotAgl, L, W, PWColor);
    hold on;
  elseif ( weights(i) < -Wmin )
    W = abs(weights(i))*max_width;
    drawedge(xstart, ystart, RotAgl, L, W, NWColor);
    hold on;
  else
    plot([xstart xend],[ystart yend],'k:','LineWidth',2.5);
  end
end

% the circle to draw around each node
angle = linspace(0,2*pi,100);
xbd = rNode*cos(angle);
ybd = rNode*sin(angle);

% draw the nodes
for i=1:n
  plot( x(i)+xbd, y(i)+ybd, 'k', 'LineWidth', wNode );
end;
axis equal;
set(gca,'Visible','off');
hold off;

%********************************************************************
% helper function to draw edges in the graph 
%********************************************************************
function drawedge( x0, y0, RotAngle, L, W, color )
xp = [     0   L      L    L   L     L     0      0  ];
yp = [-0.5*W -0.5*W -0.5*W 0 0.5*W 0.5*W 0.5*W -0.5*W];
RotMat = [cos(RotAngle) -sin(RotAngle); sin(RotAngle) cos(RotAngle)];

DrawCoordinates = RotMat*[ xp; yp ];
xd = x0 + DrawCoordinates(1,:);
yd = y0 + DrawCoordinates(2,:);

% draw the edge
patch( xd, yd, color );
