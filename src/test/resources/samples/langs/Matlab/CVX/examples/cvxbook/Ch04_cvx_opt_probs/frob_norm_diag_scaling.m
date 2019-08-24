% Section 4.5.4: Frobenius norm diagonal scaling (GP)
% Boyd & Vandenberghe "Convex Optimization"
% Joelle Skaf - 01/29/06
% Updated to use GP mode by Almir Mutapcic 02/08/06
%
% Given a square matrix M, the goal is to find a vector (with dii > 0)
% such that ||DMD^{-1}||_F is minimized, where D = diag(d).
% The problem can be cast as an unconstrained geometric program:
%           minimize sqrt( sum_{i,j=1}^{n} Mij^2*di^2/dj^2 )
%

rs = randn( 'state' );
randn( 'state', 0 );

% matrix size (M is an n-by-n matrix)
n = 4;
M = randn(n,n);

% formulating the problem as a GP
cvx_begin gp
  variable d(n)
  minimize( sqrt( sum( sum( diag(d.^2)*(M.^2)*diag(d.^-2) ) ) ) )
  % Alternate formulation: norm( diag(d)*abs(M)*diag(1./d), 'fro' )
cvx_end

% displaying results
D = diag(d);
disp('The matrix D that minimizes ||DMD^{-1}||_F is: ');
disp(D);
disp('The minimium Frobenius norm achieved is: ');
disp(norm(D*M*inv(D),'fro'));
disp('while the Frobunius norm of the original matrix M is: ');
disp(norm(M,'fro'));
