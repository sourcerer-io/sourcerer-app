% Examples from the CVX Users' guide

has_quadprog = exist( 'quadprog' );
has_quadprog = has_quadprog == 2 | has_quadprog == 3;
has_linprog  = exist( 'linprog' );
has_linprog  = has_linprog == 2 | has_linprog == 3;
rnstate = randn( 'state' ); randn( 'state', 1 );
s_quiet = cvx_quiet(true);
s_pause = cvx_pause(false);
cvx_clear; echo on

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SECTION 2.1: LEAST SQUARES %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Input data
m = 16; n = 8;
A = randn(m,n);
b = randn(m,1);

% Matlab version
x_ls = A \ b;

% cvx version
cvx_begin
    variable x(n)
    minimize( norm(A*x-b) )
cvx_end

echo off

% Compare
disp( sprintf( '\nResults:\n--------\nnorm(A*x_ls-b): %6.4f\nnorm(A*x-b):    %6.4f\ncvx_optval:     %6.4f\ncvx_status:     %s\n', norm(A*x_ls-b), norm(A*x-b), cvx_optval, cvx_status ) );
disp( 'Verify that x_ls == x:' );
disp( [ '   x_ls  = [ ', sprintf( '%7.4f ', x_ls ), ']' ] );
disp( [ '   x     = [ ', sprintf( '%7.4f ', x ), ']' ] );
disp( 'Residual vector:' );
disp( [ '   A*x-b = [ ', sprintf( '%7.4f ', A*x-b ), ']' ] );
disp( ' ' );

try input( 'Press Enter/Return for the next example...' ); clc; catch, end
echo on

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SECTION 2.2: BOUND-CONSTRAINED LEAST SQUARES %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% More input data
bnds = randn(n,2);
l = min( bnds, [] ,2 );
u = max( bnds, [], 2 );

if has_quadprog,
    % Quadprog version
    x_qp = quadprog( 2*A'*A, -2*A'*b, [], [], [], [], l, u );
else
    % quadprog not present on this system.
end

% cvx version
cvx_begin
    variable x(n)
    minimize( norm(A*x-b) )
    subject to
        l <= x <= u
cvx_end

echo off

% Compare
if has_quadprog,
    disp( sprintf( '\nResults:\n--------\nnorm(A*x_qp-b): %6.4f\nnorm(A*x-b):    %6.4f\ncvx_optval:     %6.4f\ncvx_status:     %s\n', norm(A*x_qp-b), norm(A*x-b), cvx_optval, cvx_status ) );
    disp( 'Verify that l <= x_qp == x <= u:' );
    disp( [ '   l     = [ ', sprintf( '%7.4f ', l ), ']' ] );
    disp( [ '   x_qp  = [ ', sprintf( '%7.4f ', x_qp ), ']' ] );
    disp( [ '   x     = [ ', sprintf( '%7.4f ', x ), ']' ] );
    disp( [ '   u     = [ ', sprintf( '%7.4f ', u ), ']' ] );
else
    disp( sprintf( '\nResults:\n--------\nnorm(A*x-b): %6.4f\ncvx_optval:  %6.4f\ncvx_status:  %s\n', norm(A*x-b), cvx_optval, cvx_status ) );
    disp( 'Verify that l <= x <= u:' );
    disp( [ '   l     = [ ', sprintf( '%7.4f ', l ), ']' ] );
    disp( [ '   x     = [ ', sprintf( '%7.4f ', x ), ']' ] );
    disp( [ '   u     = [ ', sprintf( '%7.4f ', u ), ']' ] );
end
disp( 'Residual vector:' );
disp( [ '   A*x-b = [ ', sprintf( '%7.4f ', A*x-b ), ']' ] );
disp( ' ' );

try input( 'Press Enter/Return for the next example...' ); clc; catch, end
echo on

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SECTION 2.3: OTHER NORMS AND FUNCTIONS: INFINITY NORM %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if has_linprog,
    % linprog version
    f    = [ zeros(n,1);  1          ];
    Ane  = [ +A,          -ones(m,1) ; ...
             -A,          -ones(m,1) ];
    bne  = [ +b;          -b         ];
    xt   = linprog(f,Ane,bne);
    x_lp = xt(1:n,:);
else
    % linprog not present on this system.
end

% cvx version
cvx_begin
    variable x(n)
    minimize( norm(A*x-b,Inf) )
cvx_end

echo off

% Compare
if has_linprog,
    disp( sprintf( '\nResults:\n--------\nnorm(A*x_lp-b,Inf): %6.4f\nnorm(A*x-b,Inf):    %6.4f\ncvx_optval:         %6.4f\ncvx_status:         %s\n', norm(A*x_lp-b,Inf), norm(A*x-b,Inf), cvx_optval, cvx_status ) );
    disp( 'Verify that x_lp == x:' );
    disp( [ '   x_lp  = [ ', sprintf( '%7.4f ', x_lp ), ']' ] );
    disp( [ '   x     = [ ', sprintf( '%7.4f ', x ), ']' ] );
else
    disp( sprintf( '\nResults:\n--------\nnorm(A*x-b,Inf): %6.4f\ncvx_optval:      %6.4f\ncvx_status:      %s\n', norm(A*x-b,Inf), cvx_optval, cvx_status ) );
    disp( 'Optimal vector:' );
    disp( [ '   x     = [ ', sprintf( '%7.4f ', x ), ']' ] );
end
disp( sprintf( 'Residual vector; verify that the peaks match the objective (%6.4f):', cvx_optval ) );
disp( [ '   A*x-b = [ ', sprintf( '%7.4f ', A*x-b ), ']' ] );
disp( ' ' );

try input( 'Press Enter/Return for the next example...' ); clc; catch, end
echo on

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SECTION 2.3: OTHER NORMS AND FUNCTIONS: ONE NORM %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if has_linprog,
    % Matlab version
    f    = [ zeros(n,1); ones(m,1);  ones(m,1)  ];
    Aeq  = [ A,          -eye(m),    +eye(m)    ];
    lb   = [ -Inf*ones(n,1);  zeros(m,1); zeros(m,1) ];
    xzz  = linprog(f,[],[], Aeq,b,lb,[]);
    x_lp = xzz(1:n,:) - xzz(n+1:2*n,:);
else
    % linprog not present on this system
end

% cvx version
cvx_begin
    variable x(n)
    minimize( norm(A*x-b,1) )
cvx_end

echo off

% Compare
if has_linprog,
    disp( sprintf( '\nResults:\n--------\nnorm(A*x_lp-b,1): %6.4f\nnorm(A*x-b,1): %6.4f\ncvx_optval: %6.4f\ncvx_status: %s\n', norm(A*x_lp-b,1), norm(A*x-b,1), cvx_optval, cvx_status ) );
    disp( 'Verify that x_lp == x:' );
    disp( [ '   x_lp  = [ ', sprintf( '%7.4f ', x_lp ), ']' ] );
    disp( [ '   x     = [ ', sprintf( '%7.4f ', x ), ']' ] );
else
    disp( sprintf( '\nResults:\n--------\nnorm(A*x-b,1): %6.4f\ncvx_optval: %6.4f\ncvx_status: %s\n', norm(A*x-b,1), cvx_optval, cvx_status ) );
    disp( 'Optimal vector:' );
    disp( [ '   x     = [ ', sprintf( '%7.4f ', x ), ']' ] );
end
disp( 'Residual vector; verify the presence of several zero residuals:' );
disp( [ '   A*x-b = [ ', sprintf( '%7.4f ', A*x-b ), ']' ] );
disp( ' ' );

try input( 'Press Enter/Return for the next example...' ); clc; catch, end
echo on

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SECTION 2.3: OTHER NORMS AND FUNCTIONS: LARGEST-K NORM %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% cvx specification
k = 5;
cvx_begin
    variable x(n)
    minimize( norm_largest(A*x-b,k) )
cvx_end

echo off

% Compare
temp = sort(abs(A*x-b));
disp( sprintf( '\nResults:\n--------\nnorm_largest(A*x-b,k): %6.4f\ncvx_optval: %6.4f\ncvx_status: %s\n', norm_largest(A*x-b,k), cvx_optval, cvx_status ) );
disp( 'Optimal vector:' );
disp( [ '   x     = [ ', sprintf( '%7.4f ', x ), ']' ] );
disp( sprintf( 'Residual vector; verify a tie for %d-th place (%7.4f):', k, temp(end-k+1) ) );
disp( [ '   A*x-b = [ ', sprintf( '%7.4f ', A*x-b ), ']' ] );
disp( ' ' );

try input( 'Press Enter/Return for the next example...' ); clc; catch, end
echo on

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SECTION 2.3: OTHER NORMS AND FUNCTIONS: HUBER PENALTY %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% cvx specification
cvx_begin
    variable x(n)
    minimize( sum(huber(A*x-b)) )
cvx_end

echo off

% Compare
disp( sprintf( '\nResults:\n--------\nsum(huber(A*x-b)): %6.4f\ncvx_optval: %6.4f\ncvx_status: %s\n', sum(huber(A*x-b)), cvx_optval, cvx_status ) );
disp( 'Optimal vector:' );
disp( [ '   x     = [ ', sprintf( '%7.4f ', x ), ']' ] );
disp( 'Residual vector:' );
disp( [ '   A*x-b = [ ', sprintf( '%7.4f ', A*x-b ), ']' ] );
disp( ' ' );

try input( 'Press Enter/Return for the next example...' ); clc; catch, end
echo on

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SECTION 2.4: OTHER CONSTRAINTS %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% More input data
p = 4;
C = randn(p,n);
d = randn(p,1);

% cvx specification
cvx_begin
    variable x(n);
    minimize( norm(A*x-b) )
    subject to
        C*x == d
        norm(x,Inf) <= 1
cvx_end

echo off

% Compare
disp( sprintf( '\nResults:\n--------\nnorm(A*x-b): %6.4f\ncvx_optval: %6.4f\ncvx_status: %s\n', norm(A*x-b), cvx_optval, cvx_status ) );
disp( 'Optimal vector:' );
disp( [ '   x     = [ ', sprintf( '%7.4f ', x ), ']' ] );
disp( 'Residual vector:' );
disp( [ '   A*x-b = [ ', sprintf( '%7.4f ', A*x-b ), ']' ] );
disp( 'Equality constraints:' );
disp( [ '   C*x   = [ ', sprintf( '%7.4f ', C*x ), ']' ] );
disp( [ '   d     = [ ', sprintf( '%7.4f ', d   ), ']' ] );

try input( 'Press Enter/Return for the next example...' ); clc; catch, end
echo on

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SECTION 2.5: AN OPTIMAL TRADEOFF CURVE %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% The basic problem:
% cvx_begin
%     variable x(n)
%     minimize( norm(A*x-b)+gamma(k)*norm(x,1) )
% cvx_end

echo off
disp( ' ' );
disp( 'Generating tradeoff curve...' );
cvx_pause(false);
gamma = logspace( -2, 2, 20 );
l2norm = zeros(size(gamma));
l1norm = zeros(size(gamma));
fprintf( 1, '   gamma       norm(x,1)    norm(A*x-b)\n' );
fprintf( 1, '---------------------------------------\n' );
for k = 1:length(gamma),
    fprintf( 1, '%8.4e', gamma(k) );
    cvx_begin
        variable x(n)
        minimize( norm(A*x-b)+gamma(k)*norm(x,1) )
    cvx_end
    l1norm(k) = norm(x,1);
    l2norm(k) = norm(A*x-b);
    fprintf( 1, '   %8.4e   %8.4e\n', l1norm(k), l2norm(k) );
end
plot( l1norm, l2norm );
xlabel( 'norm(x,1)' );
ylabel( 'norm(A*x-b)' );
grid
disp( 'Done. (Check out the graph!)' );
randn( 'state', rnstate );
cvx_quiet(s_quiet);
cvx_pause(s_pause);
