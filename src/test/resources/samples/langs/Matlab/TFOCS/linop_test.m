function varargout = linop_test( op, cmode, maxits )

%LINOP_TEST Performs an adjoint test on a linear operator.
%    LINOP_TEST( OP ) attempts to verify that a linear operator OP obeys
%    the inner product test: <A*x,y> = <x,A'*y> for all x, y. OP must be a
%    TFOCS linear operator with hard-coded size information; that is,
%    OP([],0) must return valid size info.
%
%    When called with a single argument, LINOP_TEST creates real test
%    vectors for X and Y. To test complex operators, use the two-argument
%    version LINOP_TEST( OP, cmode ), where:
%        cmode = 'R2R': real input, real output
%        cmode = 'R2C': real input, complex output
%        cmode = 'R2CC': real input, conjugate-symmetric complex output
%        cmode = 'C2R': complex input, real output
%        cmode = 'CC2R': conjugate-symmetric complex input, real output
%        cmode = 'C2C': complex input, complex output
%
%    The conjugate-symmetric options follow the symmetry conventions of Matlab's FFT.
%
%    LINOP_TEST( OP, CMODE, MAXITS ) performs MAXITS iterations of the
%    test loop. MAXITS=25 is the default.
%
%   myNorm = LINOP_TEST(...) returns an estimate of the myNorm of
%       the linear operator.

error(nargchk(1,3,nargin));
if isnumeric( op ),
    if nargin < 2 || isempty( cmode )
        disp('warning: for matrix inputs, this assumes the cmode is ''C2C'' unless you specify otherwise');
        cmode = 'C2C'; 
    end
    op = linop_matrix( op, cmode );
end
y_conjSymmetric     = false;
x_conjSymmetric     = false;
if nargin < 2 || isempty( cmode ),
    x_real = true;
    y_real = true;
else
    switch upper( cmode ),
        case 'R2R', x_real = true; y_real = true;
        case 'R2C', x_real = true; y_real = false;
        case 'R2CC', x_real = true; y_real = false;  y_conjSymmetric    = true;
        case 'C2R', x_real = false; y_real = true;
        case 'CC2R', x_real = false; y_real = true;  x_conjSymmetric    = true;
        case 'C2C', x_real = false; y_real = false;
        case 'CC2CC', x_real = false; y_real = false; 
            x_conjSymmetric    = true;
            y_conjSymmetric    = true; % this is probably never going to happen though
        otherwise, error( 'Invalid cmode: %s', cmode );
    end
end
if nargin < 3 || isempty(maxits),
    maxits = 25;
end
sz = op([],0);
if ~iscell(sz)
    sz = { [sz(2),1], [sz(1),1] };
elseif isempty(sz{1})
    disp('warning: could not detect the size; this often happens when using a scalar input, which represents scaling');
    if isempty( sz{2} )
        disp('  Proceeding under the assumption that the domain is 1D');
        sz{1} = [1,1];
        sz{2} = [1,1];
    else
        disp('  Proceeding under the assumption that the domain equals the range');
        sz{1}   = sz{2};
    end
elseif isempty(sz{2})
    disp('warning: could not detect the size; this often happens when using a scalar input, which represents scaling');
    disp('  Proceeding under the assumption that the domain equals the range');
    sz{2}   = sz{1};
end
nf = 0;
na = 0; 
errs = zeros(1,maxits+1);
nxe = 0; nye = 0;
for k = 1 : maxits,
    
    %
    % The adjoint test
    %
    
    if x_real,
        x = randn(sz{1});
    else
        x = randn(sz{1})+1j*randn(sz{1});
        if x_conjSymmetric
            x = make_conj_symmetrix( x );
        end
    end
    
    if y_real,
        y = randn(sz{2});
    else
        y = randn(sz{2})+1j*randn(sz{2});
        if y_conjSymmetric
            y = make_conj_symmetrix( y );
        end
    end
    
    nx = myNorm(x);
    Ax = op(x,1);
    nf = max( nf, myNorm(Ax)/nx );
    Ax_y = tfocs_dot( Ax, y ); 
    
    ny = myNorm(y);
    Ay = op(y,2);
    na = max( na, myNorm(Ay) / ny );
    Ay_x = tfocs_dot( x, Ay ); 
    
    errs(k) = abs(Ax_y-Ay_x)/(nx*ny);
    
    %
    % The myNorm iteration
    %
    
    if nxe == 0,
        if x_real,
            xx = randn(sz{1});
        else
            xx = randn(sz{1}) + 1j*randn(sz{1});
            if x_conjSymmetric
                xx = make_conj_symmetrix( xx );
            end
        end
        nxe = myNorm(xx);
    end
    yy = op(xx/nxe,1);
    nye = max(realmin,myNorm(yy));
    xx = op(yy/nye,2);
    nxe = myNorm(xx);
    
end

%
% Use the estimated singular vectors for a final adjoint est
%

if nxe > 0,
    Ax_y = tfocs_dot( op(xx,1), yy );
    Ay_x = tfocs_dot( op(yy,2), xx );
    errs(end) = abs(Ax_y-Ay_x) / (nxe*nye);
end

%
% Display the output
% 

nmax = max(nye,nxe);
myNorm_err = abs(nye-nxe) / nmax;
peak_err = max(errs) / nmax;
mean_err = mean(errs) / nmax;
rc = { 'complex', 'real', 'complex symmetric' };
fprintf( 'TFOCS linear operator test:\n' );
fprintf( '   Input size:  [' ); fprintf( ' %d', sz{1} ); fprintf( ' ], %s\n', rc{x_real+1+2*x_conjSymmetric} );
fprintf( '   Output size: [' ); fprintf( ' %d', sz{2} ); fprintf( ' ], %s\n', rc{y_real+1+2*y_conjSymmetric} );
fprintf( 'After %d iterations:\n', maxits  );
fprintf( '    myNorm estimates (forward/adjoint/error): %g/%g/%g\n', nye, nxe, myNorm_err );
fprintf( '       Gains: forward %g, adjoint %g\n', nf, na );
fprintf( '    Inner product error:\n' );
fprintf( '       Mean (absolute/relative): %g/%g\n', mean(errs), mean_err );
fprintf( '       Peak (absolute/relative): %g/%g\n', max(errs), peak_err );
fprintf( '       (inner product errors should 1e-10 or smaller)\n');

good = true;
if myNorm_err/max( nye, nxe ) > 1e-4
    fprintf('  Detected mismatch in forward/adjoint norm estimates. This is potentially a bad sign. Check your implementation\n');
    good = false;
end
if mean_err > 1e-8
    fprintf('  The mean error (relative) is high. This is a bad sign. Check your implementation\n');
    good = false;
end
if good
    fprintf('  Allowing for some roundoff error, there are no obvious errors. This is good.\n');
end

if nargout > 0
    varargout{1} = mean([nye,nxe]);
end


% Improvement as suggested by Graham Coleman
% Allows for 3D arrays.
% This also changes default behavior of 2D arrays
% to now use the Frobenius norm instead of spectral norm.
% This is wise, since it's a much quicker computation.
function y = myNorm(x)
y = norm( x(:) );

function y = make_conj_symmetrix( y )
ny = size( y, 1 );
y(1,:)  = real(y(1,:));         % DC component is 0
if round(ny/2) == ny/2  % even
    y(ny/2+1,:)     = real(y(ny/2+1,:));    % Nyquist component is 0
    y( ny:-1:(ny/2+2) )     = conj( y(2:ny/2) );
else                    % odd
    y( ny:-1:((ny+1)/2+1) ) = conj( y(2:((ny+1)/2)) );
end


% TFOCS v1.3 by Stephen Becker, Emmanuel Candes, and Michael Grant.
% Copyright 2013 California Institute of Technology and CVX Research.
% See the file LICENSE for full license information.
