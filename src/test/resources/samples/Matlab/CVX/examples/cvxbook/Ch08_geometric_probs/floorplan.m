function [W, H, w, h, x, y] = floorplan(adj_H, adj_V, rho, Amin, l, u )

% Computes a minimum-perimeter bounding box subject to positioning constraints
%
% Inputs:
%      adj_H,adj_V: adjacency matrices
%      Amin:        minimum spacing: w_i * h_i >= Amin
%      rho:         boundaries: rho <= x_i <= W-rho, rho <= y_i <= H-rho
%      l, u:        aspect ratio constraints: l_i <= h_i/w_i <= u_i
% Only adj_H and adj_V are required; the rest are optional. If n is the
% number of cells, then adj_H and adj_V must be nxn matrices, and Amin,
% l, and u must be vectors of length n. rho must be a scalar. The default
% values of rho and Amin are 0.
% Joelle Skaf - 12/04/05

if nargin < 2
    error('Insufficient number of input arguments');
end

[n1, n2] = size(adj_H);
[m1, m2] = size(adj_V);

if n1~=n2
    error('Input adjacency matrix for horizontal graph must be square');
end

if m1~=m2
    error('Input adjacency matrix for horizontal graph must be square');
end


if n1~=m1
    error('Input adjacency matrices must be of the same size');
end

n = n1;                     % number of cells

if nargin <3
    rho = 0;
end

if nargin <4
    Amin = zeros(1,n);
else
    if min(size(Amin)) ~=1
        error('Amin should be a vector');
    end
    if max(size(Amin)) ~= n
        error('Amin should have the same length as the input graphs');
    end
    if size(Amin,1)~=1
        Amin = Amin';
    end
end

if nargin == 5
    if min(size(1)) ~= 1
        error('l must be a vector');
    end
    if max(size(l)) ~= n
        error('the vector l must have same length as the input graphs');
    end
    if size(l,1) == 1
        l = l';
    end
end

if nargin == 6
    if min(size(1)) ~= 1
        error('u must be a vector');
    end
    if max(size(u)) ~= n
        error('the vector u must have same length as the input graphs');
    end
    if size(u,1) == 1
        u = u';
    end
end

if nargin < 6
    u = [];
end
if nargin < 5
    l = [];
end


% verifying that there is a directed path between any pair of cells in at
% least one of the 2 graphs

paths_H = adj_H;
paths_V = adj_V;
temp_H = adj_H^2;
temp_V = adj_V^2;
while (sum(temp_H(:))>0)
    paths_H = paths_H + temp_H;
    temp_H = temp_H*adj_H;
end
while (sum(temp_V(:))>0)
    paths_V = paths_V + temp_V;
    temp_V = temp_V*adj_V;
end

hh = paths_H + paths_H';
vv = paths_V + paths_V';
p = hh+vv+eye(n);
all_paths = p>0;
if sum(all_paths(:)) ~= n^2
    error('There must be a directed graph between every pair of cells in one or the other input graphs');
end

par_H = sum(adj_H,2);               % number of parents of each node in H
par_V = sum(adj_V,2);               % number of parents of each node in V
chi_H = sum(adj_H);                 % number of children of each node in H
chi_V = sum(adj_V);                 % number of children of each node in V

% find the root(s) for each tree
roots_H = find(par_H==0);
roots_V = find(par_V==0);

% find all non-root nodes for each tree
nodes_H = find(par_H>0);
nodes_V = find(par_V>0);

% find leaf(s) for each tree
leafs_H = find(chi_H==0);
leafs_V = find(chi_V==0);

cvx_begin quiet
        variables x(n) y(n) w(n) h(n) W H
        minimize ( W + H )
        w >= 0;
        h >= 0;
        x(leafs_H) >= rho;
        y(leafs_V) >= rho;
        x(roots_H) + w(roots_H) + rho <= W;
        y(roots_V) + h(roots_V) + rho <= H;
        for i=1:length(nodes_H)
            node = nodes_H(i);
            c = adj_H(node,:);
            prnt = find(c>0)';
            m = length(prnt);
            x(node) + w(node) + rho <= x(prnt);
        end

        for i=1:length(nodes_V)
            node = nodes_V(i);
            c = adj_V(node,:);
            prnt = find(c>0)';
            m = length(prnt);
            y(node) + h(node) + rho <= y(prnt);
        end

        if sum(size(u))~= 0
            h <= u.*w;
        end
        if sum(size(l))~= 0
            h >= l.*w;
        end
        w' >= quad_over_lin([Amin.^.5;zeros(1,n)],h');
cvx_end


