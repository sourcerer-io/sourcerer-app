% Optimal interconnect wire sizing
% Section 5.1, L. Vandenberghe, S. Boyd, and A. El Gamal
% "Optimizing dominant time constant in RC circuits"
% Original by Lieven Vandenberghe
% Adapted for CVX by Joelle Skaf - 11/25/05
% Modified by Michael Grant - 3/8/06
%
% we consider the problem of sizing an interconnect wire that connects
% a voltage source and conductance G to a capacitive load C. We divide the
% wire into n segments of length li, and width xi, i = 1,...,n, which is
% constrained as 0 <= xi <= Wmax. The total area of the interconnect wire
% is therefore sum(li*xi). We use a pi-model of each wire segment, with
% capacitors beta_i*xi and conductance alpha_i*xi.
% To minimize the total area subject to the width bound and a bound Tmax on
% dominant time constant, we solve the SDP
%               minimize        sum_{i=1}^20 xi*li
%                   s.t.        Tmax*G(x) - C(x) >= 0
%                               0 <= xi <= Wmax

%
% Circuit parameters
%

n=21;          % number of nodes; n-1 is number of segments in the wire
m=n-1;         % number of segments
beta = 0.5;    % segment has two capacitances beta*xi
alpha = 1;     % conductance is alpha*xi per segment
Go = 1;        % driver conductance
Co = 10;       % load capacitance
wmax = 1.0;    % upper bound on x

%
% Construct the capacitance and conductance matrices
%   C(x) = C0 + x1 * C1 + x2 * C2 + ... + xn * Cn
%   G(x) = G0 + x1 * G1 + x2 * G2 + ... + xn * Gn
% We assemble the coefficient matrices together as follows:
%   CC = [ C0(:) C1(:) C2(:) ... Cn(:) ]
%   GG = [ G0(:) G1(:) G2(:) ... Gn(:) ]
%

CC = zeros(n,n,m+1);
GG = zeros(n,n,m+1);
% constant terms
CC(n,n,1) = Co;
GG(1,1,1) = Go;
% segment values
for i = 1 : n - 1,
    CC(i,  i,  i+1) = beta;
    CC(i+1,i+1,i+1) = beta;
    GG(i,  i,  i+1) = +alpha;
    GG(i+1,i,  i+1) = -alpha;
    GG(i,  i+1,i+1) = -alpha;
    GG(i+1,i+1,i+1) = +alpha;
end
% Reshape for easy Matlab use
CC = reshape(CC,n*n,m+1);
GG = reshape(GG,n*n,m+1);

%
% Compute points the tradeoff curve, and the four sample points
%

npts    = 50;
delays  = linspace(400,2000,npts);
xdelays = [ 370, 400, 600, 1800 ];
xnpts   = length(xdelays);
areas   = zeros(1,npts);
xareas  = zeros(1,xnpts);
sizes   = zeros(m,xnpts);
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
        variable x(m)
        variable G(n,n) symmetric
        variable C(n,n) symmetric
        minimize( sum(x) )
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

        figure(xi+2);
        A = -inv(C)*G;
        B = -A*ones(n,1);
        T = linspace(0,2000,1000);
        Y = simple_step(A,B,T(2),length(T));
        hold off; plot(T,Y,'-');  hold on;
        xlabel('time');
        ylabel('v');

        % compute threshold delay, elmore delay, dominant time constant
        tthres=T(min(find(Y(n,:)>0.5)));
        GinvC=full(G\C);
        tdom=max(eig(GinvC));
        telm=max(sum(GinvC'));
        plot(tdom*[1;1], [0;1], '--', telm*[1;1], [0;1],'--', ...
             tthres*[1;1], [0;1], '--');
        text(tdom,0,'d');
        text(telm,0,'e');
        text(tthres,0,'t');
        title(sprintf('Step responses at the 21 nodes for solution (%d), Tmax=%g', xi, delay ));

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
% Draw wires for the four solutions
%

figure(2)
m2 = 2 * m;
x1 = reshape( [ 1 : m ; 1 : m ], 1, m2 );
x2 = x1( 1, end : -1 : 1 );
y  = [ - 0.5 * sizes(x1,:) ; + 0.5 * sizes(x2,:) ; - 0.5 * sizes(1,:)  ];
x1 = reshape( [ 0 : m - 1 ; 1 : m ], m2, 1 );
x2 = x1( end : -1 : 1, 1 );
x  = [ x1 ; x2 ; 0 ];
h = fill( x, y, ones(4*m+1,1)*[0.9,0.8,0.7,0.6] );
hold on
h2 = plot( x, y, '-' );
axis([ -0.1, m + 0.1, min(y(:))-0.25, max(y(:))+0.1 ]);
colormap(gray);
caxis([-1,1]);
title('Solutions at points on the tradeoff curve');
legends = {};
for k = 1 : xnpts,
    set( h(k), 'EdgeColor', get( h2(k), 'Color' ) );
    legends{k} = sprintf( 'Tmax=%g', xdelays(k) );
end
legend(legends{:},4);

