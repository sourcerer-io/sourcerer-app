% Plots a cantilever beam as a 3D figure.
% This is a helper function for the optimal cantilever beam example.
%
% Inputs:
%    values: an array of heights and widths of each segment
%            [h1 h2 ... hN w1 w2 ... wN]
%
% Almir Mutapcic 01/25/06

function cantilever_beam_plot(values)

N = length(values)/2;
for k = 0:N-1
  [X Y Z] = data_rect3(values(2*N-k),values(N-k),k);
  plot3(X,Y,Z); hold on;
end
hold off;

xlabel('width')
ylabel('height')
zlabel('length')
return;

%****************************************************************
function [X, Y, Z] = data_rect3(w,h,d)
%****************************************************************
% back face
X = [-w/2 w/2 w/2 -w/2 -w/2];
Y = [-h/2 -h/2 h/2 h/2 -h/2];
Z = [d d d d d];
% side face
X = [X -w/2 -w/2 -w/2 -w/2 -w/2];
Y = [Y -h/2 -h/2 h/2 h/2 -h/2];
Z = [Z d d+1 d+1 d d];
% front face
X = [X -w/2 w/2 w/2 -w/2 -w/2];
Y = [Y -h/2 -h/2 h/2 h/2 -h/2];
Z = [Z d+1 d+1 d+1 d+1 d+1];
% back side face
X = [X w/2 w/2 w/2 w/2 w/2];
Y = [Y -h/2 h/2 h/2 -h/2 -h/2];
Z = [Z d+1 d+1 d d d+1];
