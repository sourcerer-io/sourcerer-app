% Wire sizing and topology design
% Section 5.3,  L. Vandenberghe, S. Boyd, and A. El Gamal
% "Optimizing dominant time constant in RC circuits"
% Original by Lieven Vandenberghe
% Adapted for CVX by Joelle Skaf - 11/25/05
% Modified by Michael Grant - 3/8/06
%
% We size the wires for an interconnect circuit with four nodes. The
% topology of the circuit is more complex; the wires don't even form a tree
% (refer to Figure 13 in the paper).
% The problem can be formulated with the following SDP:
%               minimize        sum(xi*li)
%                   s.t.        0 <= xi <= wmax
%                               Tmax*G(x) - C(x) >= 0
% Please refer to the paper (section 2) to find what G(x) and C(x) are.

%
% Circuit parameters
%

n      = 4;    % number of nodes
m      = 6;    % number of branches
G      = 0.1;  % resistor between node 1 and 0
Co     = 10;   % load capacitance
wmax   = 10.0; % maximum width
% alpha: conductance per segment
% 2 * beta: capacitance per segment
alpha  = [ 1.0, 1.0, 1.0, 1.0, 1.0, 1.0 ];
beta   = [ 10,  10,  100, 1,   1,   1   ];

%
% Build capacitance and conductance matrices
%

CC = zeros(n,n,m+1);
GG = zeros(n,n,m+1);
% constant terms
CC(3,3,1) = Co;
GG(1,1,1) = G;
% branch 1
CC(1,1,2) = + beta(1);
CC(2,2,2) = + beta(1);
GG(1,1,2) = + alpha(1);
GG(2,1,2) = - alpha(1);
GG(1,2,2) = - alpha(1);
GG(2,2,2) = + alpha(1);
% branch 2
CC(2,2,3) = + beta(2);
CC(3,3,3) = + beta(2);
GG(2,2,3) = + alpha(2);
GG(3,2,3) = - alpha(2);
GG(2,3,3) = - alpha(2);
GG(3,3,3) = + alpha(2);
% branch 3
CC(1,1,4) = + beta(3);
CC(3,3,4) = + beta(3);
GG(1,1,4) = + alpha(3);
GG(3,1,4) = - alpha(3);
GG(1,3,4) = - alpha(3);
GG(3,3,4) = + alpha(3);
% branch 4
CC(1,1,5) = + beta(4);
CC(4,4,5) = + beta(4);
GG(1,1,5) = + alpha(4);
GG(4,1,5) = - alpha(4);
GG(1,4,5) = - alpha(4);
GG(4,4,5) = + alpha(4);
% branch 5
CC(2,2,6) = + beta(5);
CC(4,4,6) = + beta(5);
GG(2,2,6) = + alpha(5);
GG(2,4,6) = - alpha(5);
GG(4,2,6) = - alpha(5);
GG(4,4,6) = + alpha(5);
% branch 6
CC(3,3,7) = + beta(6);
CC(4,4,7) = + beta(6);
GG(3,3,7) = + alpha(6);
GG(4,3,7) = - alpha(6);
GG(3,4,7) = - alpha(6);
GG(4,4,7) = + alpha(6);

% Reshape for easy Matlab use
CC = reshape(CC,n*n,m+1);
GG = reshape(GG,n*n,m+1);

%
% Compute points the tradeoff curve, and the three sample points
%

npts    = 50;
delays  = linspace( 180, 800, npts );
xdelays = [ 200, 400, 600 ];
xnpts   = length(xdelays);
areas   = zeros(1,npts);
sizes   = zeros(6,xnpts);
for i = 1 : npts  + xnpts,

    if i > npts,
        xi = i - npts;
        delay = xdelays(xi);
        disp( sprintf( 'Particular solution %d of %d (Tmax = %g)', xi, xnpts, delay ) );
    else,
        delay = delays(i);
        disp( sprintf( 'Point %d of %d on the tradeoff curve (Tmax = %g)', i, npts, delay ) );
    end

    %
    % Construct and solve the convex model
    %

    cvx_begin sdp quiet
        variable x(6)
        variable G(n,n) symmetric
        variable C(n,n) symmetric
        minimize( sum( x ) )
        subject to
            G == reshape( GG * [ 1 ; x ], n, n );
            C == reshape( CC * [ 1 ; x ], n, n );
            delay * G - C >= 0;
            0 <= x <= wmax;
    cvx_end

    if i <= npts,
        areas(i) = cvx_optval;
    else,
        xareas(xi) = cvx_optval;
        sizes(:,xi) = x;

        %
        % Plot the step response
        %

        figure(xi+1);
        A = -inv(C)*G;
        B = -A*ones(n,1);
        T = linspace(0,1000,1000);
        Y = simple_step(A,B,T(2),length(T));
        hold off; plot(T,Y([1,3,4],:),'-');  hold on;

        % compute threshold delay, elmore delay, dominant time constant
        tthres=T(min(find(Y(3,:)>0.5)));
        tdom=max(eig(inv(G)*C));
        telm=max(sum((inv(G)*C)'));
        plot(tdom*[1;1], [0;1], '--', telm*[1;1], [0;1],'--', ...
             tthres*[1;1], [0;1], '--');
        text(tdom,0,'d');
        text(telm,0,'e');
        text(tthres,0,'t');
        title(sprintf('Step response for solution (%d), Tmax=%g', xi, delay ));

    end

end

%
% Plot the tradeoff curve
%

figure(1)
ind = isfinite(areas);
plot(areas(ind), delays(ind));
xlabel('Area');
ylabel('Tdom');
title('Area-delay tradeoff curve');
hold on
for k = 1 : xnpts,
    text( xareas(k), xdelays(k), sprintf( '(%d)', k ) );
end

%
% Display sizes for the three solutions
%

disp(['Three specific solutions:']);
sizes

