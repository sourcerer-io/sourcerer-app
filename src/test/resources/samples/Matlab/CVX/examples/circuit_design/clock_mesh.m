% Sizing of clock meshes
% Section 4, L. Vandenberghe, S. Boyd, and A. El Gamal
% "Optimal Wire and Transistor Sizing for Circuits with Non-Tree Topology"
% Original by Lieven Vanderberghe
% Adapted to CVX by Argyris Zymnis - 12/04/05
% Modified by Michael Grant - 3/8/06
%
% We consider the problem of sizing a clock mesh, so as to minimize the
% total dissipated power under a constraint on the dominant time constant.
% The numbers of nodes in the mesh is N per row or column (thus n=(N+1)^2
% in total). We divide the wire into m segments of width xi, i = 1,...,m
% which is constrained as 0 <= xi <= Wmax. We use a pi-model of each wire
% segment, with capacitance beta_i*xi and conductance alpha_i*xi.
% Defining C(x) = C0+x1*C1+x2*C2+...+xm*Cm we have that the dissipated
% power is equal to ones(1,n)*C(x)*ones(n,1). Thus to minimize the
% dissipated power subject to a constraint in the widths and a constraint
% in the dominant time constant, we solve the SDP
%               minimize        ones(1,m)*C(x)*ones(m,1)
%                   s.t.        Tmax*G(x) - C(x) >= 0
%                               0 <= xi <= Wmax

%
% Circuit parameters
%

dim=4;           % grid is dimxdim (assume dim is even)
n=(dim+1)^2;     % number of nodes
m=2*dim*(dim+1); % number of wires
                 % 1...dim(dim+1) are horizontal segments
                 % (numbered rowwise);
                 % dim(dim+1)+1 ... 2*dim(dim+1) are vertical
                 % (numbered columnwise)
beta = 0.5;      % capacitance per segment is twice beta times xi
alpha = 1;       % conductance per segment is alpha times xi
G0 = 1;          % source conductance
C0 = [ 10     2     7     5     3;
        8     3     9     5     5;
        1     8     4     9     3;
        7     3     6     8     2;
        5     2     1     9    10 ];
wmax = 1;       % upper bound on x

%
% Build capacitance and conductance matrices
%

CC = zeros(dim+1,dim+1,dim+1,dim+1,m+1);
GG = zeros(dim+1,dim+1,dim+1,dim+1,m+1);

% constant term
CC(:,:,:,:,1) = reshape( diag(C0(:)), dim+1, dim+1, dim+1, dim+1 );
zo13 = reshape( [1,0;0,1],   2, 1, 2, 1 );
zo24 = reshape( zo13,        1, 2, 1, 2 );
pn13 = reshape( [1,-1;-1,1], 2, 1, 2, 1 );
pn24 = reshape( pn13,        1, 2, 1, 2 );
for i = 1 : dim+1,
    % source conductance
    % first driver in the middle of row 1
    GG(dim/2+1,i,dim/2+1,i,1) = G0;
    for j = 1 : dim,
        % horizontal segments
        node = 1 + j + ( i - 1 ) * dim;
        CC([j,j+1],i,[j,j+1],i,node) = beta * zo13;
        GG([j,j+1],i,[j,j+1],i,node) = alpha * pn13;
        % vertical segments
        node = node + dim * ( dim + 1 );
        CC(i,[j,j+1],i,[j,j+1],node) = beta * zo24;
        GG(i,[j,j+1],i,[j,j+1],node) = alpha * pn24;
    end
end
% reshape for ease of use in Matlab
CC = reshape( CC, n*n, m+1 );
GG = reshape( GG, n*n, m+1 );

%
% Compute points the tradeoff curve, and the three sample points
%

npts    = 50;
delays  = linspace( 50, 150, npts );
xdelays = [ 50, 100 ];
xnpts   = length( xdelays );
areas   = zeros(1,npts);
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
        variable x(m)
        variable G(n,n) symmetric
        variable C(n,n) symmetric
        dual variables Y1 Y2 Y3 Y4 Y5
        minimize( sum( C(:) ) )
        subject to
            G == reshape( GG * [ 1 ; x ], n, n );
            C == reshape( CC * [ 1 ; x ], n, n );
            delay * G - C >= 0;
            0 <= x <= wmax;
    cvx_end

    if i <= npts,
        areas(i) = sum(x);
    else,
        xareas(xi) = sum(x);

        %
        % Display sizes
        %

        disp( sprintf( 'Solution %d:', xi ) );
        disp( 'Vertical segments:' );
        reshape( x(1:dim*(dim+1),1), dim, dim+1 )
        disp( 'Horizontal segments:' );
        reshape( x(dim*(dim+1)+1:end), dim, dim+1 )

        %
        % Determine the step responses
        %

        figure(xi+1);
        A = -inv(C)*G;
        B = -A*ones(n,1);
        T = linspace(0,500,2000);
        Y = simple_step(A,B,T(2),length(T));
        indmax = 0;
        indmin = Inf;
        for j = 1 : size(Y,1),
           inds = min(find(Y(j,:) >= 0.5));
           if ( inds > indmax )
              indmax = inds;
              jmax = j;
           end;
           if ( inds < indmin )
              indmin = inds;
              jmin = j;
           end;
        end;
        tthres = T(indmax);
        GinvC  = full( G \ C );
        tdom   = max(eig(GinvC));
        elmore = max(sum(GinvC'));
        hold off; plot(T,Y(jmax,:),'-',T,Y(jmin,:));  hold on;
        plot( tdom   * [1;1], [0;1], '--', ...
              elmore * [1;1], [0;1], '--', ...
              tthres * [1;1], [0;1], '--');
        axis([0 500 0 1])
        text(tdom,1,'d');
        text(elmore,1,'e');
        text(tthres,1,'t');
        text( T(600), Y(jmax,600), sprintf( 'v%d', jmax ) );
        text( T(600), Y(jmin,600), sprintf( 'v%d', jmin ) );
        title( sprintf( 'Solution %d (Tmax=%g), fastest and slowest step responses', xi, delay ) );

    end

end;

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

