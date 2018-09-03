% Minimum volume ellipsoid covering union of ellipsoids
% Section 8.4.1, Boyd & Vandenberghe "Convex Optimization"
% Original version by Lieven Vandenberghe
% Updated for CVX by Almir Mutapcic - Jan 2006
% (a figure is generated)
%
% We find a smallest ellipsoid containing m ellipsoids
% { x'*A_i*x + 2*b_i'*x + c < 0 }, for i = 1,...,m
%
% Problem data:
% As = {A1, A2, ..., Am}:  cell array of m pos. def. matrices
% bs = {b1, b2, ..., bm}:  cell array of m 2-vectors
% cs = {c1, c2, ..., cm}:  cell array of m scalars

% ellipse data
As = {}; bs = {}; cs = {};
As{1} = [ 0.1355    0.1148;  0.1148    0.4398];
As{2} = [ 0.6064   -0.1022; -0.1022    0.7344];
As{3} = [ 0.7127   -0.0559; -0.0559    0.9253];
As{4} = [ 0.2706   -0.1379; -0.1379    0.2515];
As{5} = [ 0.4008   -0.1112; -0.1112    0.2107];
bs{1} = [ -0.2042  0.0264]';
bs{2} = [  0.8259 -2.1188]';
bs{3} = [ -0.0256  1.0591]';
bs{4} = [  0.1827 -0.3844]';
bs{5} = [  0.3823 -0.8253]';
cs{1} = 0.2351;
cs{2} = 5.8250;
cs{3} = 0.9968;
cs{4} = -0.2981;
cs{5} = 2.6735;

% dimensions
n = 2;
m = size(bs,2);    % m ellipsoids given

% construct and solve the problem as posed in the book
cvx_begin sdp
    variable Asqr(n,n) symmetric
    variable btilde(n)
    variable t(m)
    maximize( det_rootn( Asqr ) )
    subject to
        t >= 0;
        for i = 1:m
            [ -(Asqr - t(i)*As{i}), -(btilde - t(i)*bs{i}), zeros(n,n);
              -(btilde - t(i)*bs{i})', -(- 1 - t(i)*cs{i}), -btilde';
               zeros(n,n), -btilde, Asqr] >= 0;
        end
cvx_end

% convert to ellipsoid parametrization E = { x | || Ax + b || <= 1 }
A = sqrtm(Asqr);
b = A\btilde;

% plot ellipsoids using { x | || A_i x + b_i || <= alpha } parametrization
noangles = 200;
angles   = linspace( 0, 2 * pi, noangles );

clf
for i=1:m
  Ai = sqrtm(As{i}); bi = Ai\bs{i};
  alpha = bs{i}'*inv(As{i})*bs{i} - cs{i};
  ellipse  = Ai \ [ sqrt(alpha)*cos(angles)-bi(1) ; sqrt(alpha)*sin(angles)-bi(2) ];
  plot( ellipse(1,:), ellipse(2,:), 'b-' );
  hold on
end
ellipse  = A \ [ cos(angles) - b(1) ; sin(angles) - b(2) ];

plot( ellipse(1,:), ellipse(2,:), 'r--' );
axis square
axis off
hold off
