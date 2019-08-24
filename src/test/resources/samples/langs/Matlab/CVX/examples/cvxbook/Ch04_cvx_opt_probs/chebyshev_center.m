% Section 4.3.1: Compute the Chebyshev center of a polyhedron
% Boyd & Vandenberghe "Convex Optimization"
% Joëlle Skaf - 08/16/05
%
% The goal is to find the largest Euclidean ball (i.e. its center and
% radius) that lies in a polyhedron described by linear inequalites in this
% fashion: P = {x : a_i'*x <= b_i, i=1,...,m}

% Generate the data
randn('state',0);
n = 10; m = 2*n;
A = randn(m,n);
b = A*rand(n,1) + 2*rand(m,1);
norm_ai = sum(A.^2,2).^(.5);

% Build and execute model
fprintf(1,'Computing Chebyshev center...');
cvx_begin
    variable r(1)
    variable x_c(n)
    dual variable y
    maximize ( r )
    y: A*x_c + r*norm_ai <= b;
cvx_end
fprintf(1,'Done! \n');

% Display results
fprintf(1,'The Chebyshev center coordinates are: \n');
disp(x_c);
fprintf(1,'The radius of the largest Euclidean ball is: \n');
disp(r);
