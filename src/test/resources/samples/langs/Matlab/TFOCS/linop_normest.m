function [ nxe, cnt ] = linop_normest( op, cmode, tol, maxiter )

%LINOP_NORMEST Estimates the operator norm.
%    EST = LINOP_NORMEST( OP ) estimates the induced norm of the operator:
%           || OP || = max_{||x||<=1} ||OP(X)||
%    using a simple power method similar to the MATLAB NORMEST functon.
%
%    When called with a single argument, LINOP_TEST begins with a real
%    initial vector. To test complex operators, use the two-argument
%    version LINOP_NORMEST( OP, cmode ), where:
%        cmode = 'R2R': real input, real output
%        cmode = 'R2C': real input, complex output
%        cmode = 'C2R': imag input, imag output
%        cmode = 'C2C': complex input, complex output
%
%    LINOP_NORMEST( OP, CMODE, TOL, MAXITER ) stops the iteration when the
%    relative change in the estimate is less than TOL, or after MAXITER
%    iterations, whichever comes first.
%
%    [ EST, CNT ] = LINOP_NORMEST( ... returns the estimate and the number
%    of iterations taken, respectively.

if isnumeric( op ),
    op = linop_matrix( op, 'C2C' );
elseif ~isa( op, 'function_handle' ),
    error( 'Argument must be a function handle or matrix.' );
end
x_real = true;
if nargin >= 2 && ~isempty( cmode ),
    switch upper( cmode ),
        case { 'R2R', 'R2C' }, x_real = true;
        case { 'C2R', 'C2C' }, x_real = false;
        otherwise, error( 'Invalid cmode: %s', cmode );
    end
end
if nargin < 3 || isempty( tol ),
    tol = 1e-8;
end
if nargin < 4 || isempty( maxiter ),
    maxiter = 50;
end
sz = op([],0);
if iscell( sz ),
    sz = sz{1};
elseif ~isempty(sz)
    sz = [sz(2),1];
else
    % if the input is the identity, it may not have a size associated with it,
    % so current behavior is to try an arbitrary size:
    sz = [50,1];
end
cnt = 0;
nxe = 0;
while true,
    if nxe == 0,
        if x_real,
            xx = randn(sz);
        else
            xx = randn(sz) + 1j*randn(sz);
        end
        nxe = sqrt( tfocs_normsq( xx ) );
    end
    yy = op( xx / max( nxe, realmin ), 1 );
    nye = sqrt( tfocs_normsq( yy ) );
    xx = op( yy / max( nye, realmin ), 2 );
    nxe0 = nxe;
    nxe = sqrt( tfocs_normsq( xx ) );
    if abs( nxe - nxe0 ) < tol * max( nxe0, nxe ),
        break;
    end
    cnt = cnt + 1;
    if cnt >= maxiter,
        break;
    end
end

% TFOCS v1.3 by Stephen Becker, Emmanuel Candes, and Michael Grant.
% Copyright 2013 California Institute of Technology and CVX Research.
% See the file LICENSE for full license information.
