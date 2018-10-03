% Example 8.3: Bounding correlation coefficients
% Boyd & Vandenberghe "Convex Optimization"
% Joelle Skaf - 10/09/05
%
% Let C be a correlation matrix. Given lower and upper bounds on
% some of the angles (or correlation coeff.), find the maximum and minimum
% possible values of rho_14 by solving 2 SDP's
%           minimize/maximize   rho_14
%                        s.t.   C >=0
%                               0.6 <= rho_12 <=  0.9
%                               0.8 <= rho_13 <=  0.9
%                               0.5 <= rho_24 <=  0.7
%                              -0.8 <= rho_34 <= -0.4

n = 4;

% Upper bound SDP
fprintf(1,'Solving the upper bound SDP ...');

cvx_begin sdp
    variable C1(n,n) symmetric
    maximize ( C1(1,4) )
    C1 >= 0;
    diag(C1) == ones(n,1);
    C1(1,2) >= 0.6;
    C1(1,2) <= 0.9;
    C1(1,3) >= 0.8;
    C1(1,3) <= 0.9;
    C1(2,4) >= 0.5;
    C1(2,4) <= 0.7;
    C1(3,4) >= -0.8;
    C1(3,4) <= -0.4;
cvx_end

fprintf(1,'Done! \n');

% Lower bound SDP
fprintf(1,'Solving the lower bound SDP ...');

cvx_begin sdp
    variable C2(n,n) symmetric
    minimize ( C2(1,4) )
    C2 >= 0;
    diag(C2) == ones(n,1);
    C2(1,2) >= 0.6;
    C2(1,2) <= 0.9;
    C2(1,3) >= 0.8;
    C2(1,3) <= 0.9;
    C2(2,4) >= 0.5;
    C2(2,4) <= 0.7;
    C2(3,4) >= -0.8;
    C2(3,4) <= -0.4;
cvx_end

fprintf(1,'Done! \n');
% Displaying results
disp('--------------------------------------------------------------------------------');
disp(['The minimum and maximum values of rho_14 are: ' num2str(C2(1,4)) ' and ' num2str(C1(1,4))]);
disp('with corresponding correlation matrices: ');
disp(C2)
disp(C1)
