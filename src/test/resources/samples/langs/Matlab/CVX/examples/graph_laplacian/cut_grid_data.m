function [A,xy]= cut_grid_data

% Generate a cut-grid graph for the ICM 2006 talk example
%
% The graph has 64 nodes and 95 edges
% A is an n x m incidence matrix (n is number of nodes, m is number of edges)
% xy is the location data
%
% Original code by Arpita Ghosh, modified for ICM06 talk by Almir Mutapcic

n  = 8; 
r1 = 2;
y  = ones(n,1) * [1:n];
x  = y';
x  = x(:);
y  = y(:);
dx = x * ones(1,n^2);
dy = y * ones(1,n^2);
xy = [ x, y ];

% Find the adjacency matrix, manually deleting edges to get down to size
Adj1 = tril( ( dx - dx' ) .^ 2 + ( dy - dy' ) .^2 < r1, -1 );
Adj1(49,41) = 0;
Adj1(50,42) = 0; 
Adj1(16,8)  = 0;
Adj1(24,16) = 0;
Adj1(15,7)  = 0;
Adj1(23,15) = 0;
Adj1(10,1)  = 0; 
Adj1(21,13) = 0;
Adj1(13,5)  = 0; 
Adj1(22,14) = 0;
Adj1(14,6)  = 0; 
Adj1(51,43) = 0; 
Adj1(52,44) = 0; 
Adj1(53,45) = 0; 
Adj1(54,46) = 0; 
Adj1(42,41) = 0;
Adj1(34,33) = 0;
Adj1(26,25) = 0;

% Build the incidence matrix
[i,j,v] = find(Adj1);
m = length(i);
A = sparse( [i;j], [1:m,1:m]', [ones(m,1);-ones(m,1)] );

