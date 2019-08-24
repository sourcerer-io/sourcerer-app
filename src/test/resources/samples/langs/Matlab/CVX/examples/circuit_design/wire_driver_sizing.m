% Combined sizing of drivers, repeaters, and wire
% Section 5.2,  L. Vandenberghe, S. Boyd, and A. El Gamal
% "Optimizing dominant time constant in RC circuits"
% Original by Lieven Vandenberghe
% Adapted for CVX by Joelle Skaf - 11/25/05
% Modified by Michael Grant - 3/8/06
%
% The first driver drives an interconnect wire, modeled as n RC Pi segments
% connected to a repeater, which drives a capacitive load through another n
% segment wires. The problem is to determine the sizes of the wire segments
% (x1, . . . , x40) and the sizes of the driver & repeater d1 and d2.
% We want to minimize area subject to bound on the combined delay Tdom1 +
% Tdom2 of the two stages.
%               minimize        L(d1 + d2) + sum(xi*li)
%                   s.t.        0 <= xi <= wmax
%                               d1 >=0 , d2 >= 0
%                               (Tmax/2)G1(x, d1, d2) - C1(x,d2) >= 0
%                               (Tmax/2)G2(x, d1, d2) - C2(x) >= 0

%
% Circuit parameters
%

n = 21;        % number of nodes per wire
m = n-1;       % number of segments per wire
g = 1.0;       % output conductance is g times driver size
c0 = 1.0;      % input capacitance of driver is co + c*driver size
c = 3.0;
alpha = 10;    % wire segment: two capacitances beta*width
beta = 0.5;    % wire segment: conductance alpha*width
C = 50;        % external load
L = 10.0;      % area is sum xi + L*(d1+d2)
wmax = 2.0;    % maximum wire width
dmax = 100.0;  % maximum driver size

%
% Construct the capacitance and conductance matrices
%   C1(x) = C10 + w11 * C11 + w21 * C12 + ...
%   C2(x) = C20 + w11 * C21 + w21 * C22 + ...
%   G1(x) = G10 + w11 * G11 + w21 * G12 + ...
%   G2(x) = G20 + w11 * G21 + w21 * G22 + ...
% and we assemble the coefficient matrices together as follows:
%   CC = [ C10(:) C11(:) C12(:) ... ; C20(:) C21(:) C22(:) ... ]
%   GG = [ G10(:) G11(:) G12(:) ... ; C20(:) C21(:) C22(:) ... ]
%
%

CC = zeros(n,n,2,2*m+3);
GG = zeros(n,n,2,2*m+3);
% load on first circuit from second driver = c0 + c * d2
CC(n,n,1,1    ) = c0;
CC(n,n,1,2*m+3) = c;
% external load
CC(n,n,2,1) = C;
% output conductances of drivers
GG(1,1,1,2*m+2) = g;
GG(1,1,2,2*m+3) = g;
% segment capacitances and conductances
for i = 1 : n-1,
    CC(i:i+1,i:i+1,1,  i+1) =  beta * [1, 0; 0,1];
    CC(i:i+1,i:i+1,2,m+i+1) =  beta * [1, 0; 0,1];
    GG(i:i+1,i:i+1,1,  i+1) = alpha * [1,-1;-1,1];
    GG(i:i+1,i:i+1,2,m+i+1) = alpha * [1,-1;-1,1];
end
% reshape for Matlab use
CC = reshape( CC, n*n*2, 2*m+3 );
GG = reshape( GG, n*n*2, 2*m+3 );

%
% Compute points the tradeoff curve and the sample solution
%

npts    = 50;
delays  = linspace( 150, 500, npts );
xdelays = 189;
xnpts   = length( xdelays );
areas   = zeros( 1, npts );
xareas  = zeros( 1, xnpts );
for i = 1 : npts + xnpts,

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
        variables w(m,2) d(1,2)
        variable G(n,n,2) symmetric
        variable C(n,n,2) symmetric
        minimize( L * sum(d) + sum(w(:)) );
        G == reshape( GG * [ 1 ; w(:) ; d(:) ], n, n, 2 );
        C == reshape( CC * [ 1 ; w(:) ; d(:) ], n, n, 2 );
        % This is actually two LMIs, one for each circuit
        (delay/2) * G - C >= 0;
        0 <= w(:) <= wmax;
        d(:) >= 0;
    cvx_end

    if i <= npts,
        areas(i) = cvx_optval;
    else
        xareas(xi) = cvx_optval;

        %
        % Draw solution, plotting drivers as a block with width os
        % and height L/(2*os).
        %

        figure(2*xi);
        os = 3;
        m2 = 2 * m;
        ss = max( L * max( d ) / os, max( w(:) ) );
        x  = reshape( [ 1 : m ; 1 : m ], 1, m2 );
        y  = 0.5 * [ - w(x,:) ; w(x(end:-1:1),:) ; + w(1,:) ];
        yd = ( 0.5 * L / os ) * [ -d ; -d ; +d ; +d ; -d ];
        x   = reshape( [ 0 : m - 1 ; 1 : m ], m2, 1 );
        x   = [ x ; x(end:-1:1,:) ; 0 ];
        xd  = [ 0 ; os ; os ; 0 ; 0 ];
        x   = x + os + 0.5;
        xd  = [ xd, xd + os + m + 1 ];
        x   = [ x, x + os + m + 1 ];
        fill( x, y, 0.9 * ones(size(y)), xd, yd, 0.9 * ones(size(yd)) );
        hold on
        plot( x, y, '-', xd, yd, '-' );
        axis( [-0.5, 2*m+2*os+2, -0.5*ss-0.1,0.5*ss+0.1 ] );
        set( gca, 'XTick', [x(1,1),x(1,1)+m,x(1,2),x(1,2)+m] );
        set( gca, 'XTicklabel', {'0',num2str(m),'0',num2str(m)} );
        colormap(gray);
        caxis([-1,1])
        title(sprintf('Sample solution (%d), Tmax = %g', xi, delay ));

        %
        % Build the state space models and plot step responses
        %

        figure(2*xi+1);
        T = linspace(0,1000,1000);
        tdom = []; telm = []; tthresh = []; Y = {};
        for k = 1 : 2,
            A = -inv(C(:,:,k))*G(:,:,k);
            B = -A* ones(n,1);
            tdom(k) = max(eig(inv(G(:,:,k))*C(:,:,k)));
            telm(k) = max(sum((inv(G(:,:,k))*C(:,:,k))'));
            Y{k} = simple_step(A,B,T(2),length(T));
            Y{k} = Y{k}(n,:);
            tthresh(k) = min(find(Y{k}>=0.5));
        end
        plot( T, Y{1}, '-', T, Y{2}, '-' );
        axis([0 T(500) 0 1]);
        xlabel('time');
        ylabel('v');
        hold on;
        text(tdom(1),0,'d1');
        text(telm(2),0,'e1');
        text(tthresh(1),0,'t1');
        text(tdom(1)+tdom(2),0,'d2');
        text(tdom(1)+telm(2),0,'e2');
        text(tdom(1)+tthresh(2),0,'t2');
        plot(tdom(1)*[1;1],[0;1],'--');
        plot(telm(1)*[1;1],[0;1],'--');
        plot(tthresh(1)*[1;1],[0;1],'--');
        plot((tdom(1)+tdom(2))*[1;1],[0;1],'--');
        plot((tdom(1)+telm(2))*[1;1],[0;1],'--');
        plot((tdom(1)+tthresh(2))*[1;1],[0;1],'--');
        title(sprintf('Step responses for sample solution (%d), Tmax = %g', xi, delay ));

     end

end

%
% Plot tradeoff curve
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

