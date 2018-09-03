function [ cvx_optval, success ] = quad_form( x, Q, v, w )

%QUAD_FORM   Internal cvx version.

%
% Check sizes and types
%

narginchk(2,4);
tol = 16 * eps;
tolLDL = 4 * eps;
if nargin < 4,
    w = 0;
    if nargin < 3,
        v = 0;
    end
end
sx = size( x );
if length( sx ) ~= 2 || all( sx ~= 1 ),
    error( 'The first argument must be a vector.' );
else
    sx = prod( sx );
end
sQ = size( Q );
if length( sQ ) ~= 2 || sQ( 1 ) ~= sQ( 2 ),
    error( 'The second argument must be a scalar or a square matrix.' );
elseif all( sQ( 1 ) ~= [ 1, sx ] ),
    error( 'The size of Q is incompatible with the size of x.' );
end
sv = size( v );
if length( sv ) > 2 || all( sv ~= 1 ),
    error( 'The third argument must be a vector.' );
elseif all( prod( sv ) ~= [ 1, sx ] ),   
    error( 'The size of v is incompatible with the size of x.' );
else
    sv = prod( sv );
end
if numel( w ) ~= 1,
    error( 'The fourth argument must be a real scalar.' );
end

w = real( w );
v = vec( v );
x = vec( x );
success = true;
if cvx_isconstant( x ),
    
    %
    % Constant x, affine Q
    %

    x = cvx_constant( x );
    cvx_optval = real( x' * Q * x ) + sum( real( v' * x ) ) + w;
    return

elseif ~cvx_isaffine( x ),

    error( 'First argument must be affine.' );
    
elseif ~cvx_isconstant( Q ) || ~cvx_isconstant( v ),
    
    error( 'Either x or (Q,v) must be constant.' );
    
end
Q = cvx_constant( Q );
v = cvx_constant( v );
if nnz( Q ) == 0,
    
    %
    % Zero Q, affine x
    %

    cvx_optval = sum( real( v' * x ) ) + w;
    return
    
elseif sQ( 1 ) == 1,
    
    %
    % Constant scalar Q, affine x
    %
    
    x = x + 0.5 * ( v / Q );
    w = w - 0.25 * ( v' * v ) / Q;
    cvx_optval = real( Q ) * sum_square_abs( x ) + w;
    return
    
else

    %
    % Constant matrix Q, affine x
    %

    if sv < sx, 
        v = v(ones(sx,1),1); 
    end
    cvx_optval = w;
    while true,
        
        %
        % Remove zero rows and columns from Q. If a diagonal element of Q is
        % zero but there are elements on that row or column that are not,
        % then we know that neither Q nor -Q is PSD.
        %
        
        Q = 0.5 * ( Q + Q' );
        dQ = diag( Q );
        trQ = sum( dQ );
        if ~all( dQ ),
            nnzQ = nnz( Q );
            tt = dQ ~= 0;
            Q = Q( tt, tt );
            if nnz( Q ) ~= nnzQ,
                success = false;
                break
            end
            dQ = dQ( tt );
            if nnz( v ),
                cvx_optval = cvx_optval + real( v( ~tt, : )' * cvx_subsref( x, ~tt, ':' ) );
            end
            v = v( tt, : );
            x = cvx_subsref( x, tt, ':' );
            sx = length( x );
        end
        
        %
        % Determine the sign of the elements of Q. If they are not all of
        % the same sign, then neither Q nor -Q is PSD. Note that trQ has
        % preserved the sign of our quadratic form, so setting Q=-Q here
        % in the concave case does not cause a problem.
        %

        dQ = dQ > 0;
        if ~all( dQ ),
            if any( dQ ),
                success = false;
            else
                Q = -Q;
            end
        end
        
        %
        % We've had to modify this portion of the code because MATLAB has
        % removed support for the CHOLINC function.
        %
        % First, try a Cholesky. If it successfully completes its
        % factorization without fail, we accept it without question. If
        % it terminates early, we perform a numerical test to see if the
        % result still approximates the square root to good precision.
        %
        % If Cholesky fails, then we assume the matrix is either rank
        % deficient or indefinite. For sparse matrices, we perform an LDL
        % factorization, and remove the contributions of any 2x2 blocks,
        % negative 1x1 blocks, and near-zero 1x1 blocks on the diagonal.
        % If there are no such blocks, we accept it without question; if
        % so, we perform the same numerical test. If the test fails, we 
        % assume, for sparse matrices, at least, that the matrix is
        % indefinite.
        %
        % If the matrix is dense, our final test is an eigenvalue
        % decomposition, the most expensive but the most accurate.
        %

        spQ = nnz(Q) <= 0.1 * sx * sx;
        if spQ,
            Q = sparse( Q );
            [ R, p, prm ] = chol( Q, 'upper', 'vector' );
            if any( diff(prm) ~= 1 ),
                R( :, prm ) = R; %#ok
            end
        else
            Q = full( Q );
            [ R, p ] = chol( Q, 'upper' );
            if p > 1, 
                R = [ R , R' \ Q(1:p-1,p:end) ]; %#ok
            end
        end
        valid = p == 0;
        if ~valid,
            tolQ = tol * norm( Q, 'fro' );
            if p > 1,
                valid = norm( Q - R' * R, 'fro' ) < tolQ;
            end
        end
        if ~valid && spQ,
            [ R, DD, prm ] = ldl( sparse( Q ), 'upper', 'vector' );
            if nnz( R ) > 0.2 * sx * ( sx + 1 ) / 2, spQ = false; end %#ok
            spQ = cvx_use_sparse( R );
            tt = diag(DD,1) == 0;
            tt = [ tt ; true ] & [ true ; tt ] & ( diag(DD) > tolLDL * trQ );
            DD = diag(DD);
            R  = bsxfun( @times, sqrt( DD(tt,:) ), R(tt,:) );
            if any( diff(prm) ~= 1 ), R( :, prm ) = R; end
            valid = all( tt ) || norm( Q - R' * R, 'fro' ) < tolQ;
        end
        if ~valid && ~spQ,
            [ V, D ] = eig( full( Q ) );
            if cvx_use_sparse( V ), 
                V = sparse( V ); 
            end
            D = diag( D );
            if any( D(2:end) < D(1:end-1) ),
                [D,ndxs] = sort(D);
                V = V(:,ndxs);
            end
            valid = D(1) > -tol * D(end);
            if valid,
                nzero = nnz( cumsum(D) < tol * abs(trQ) );
                V = V(:,nzero+1:end);
                D = sqrt(D(nzero+1:end));
                R = diag(sparse(D)) * V';
            end
        end
        if ~valid,
            success = false;
            break;
        end
        
        %
        % Scale so that the mean eigenvalue of (1/alpha)*R'*R is one. 
        % Hopefully this will minimize scaling issues.
        %
       
        alpha = trQ / size(R,1);
        cvx_optval = cvx_optval + alpha * sum_square_abs( ( R * x ) / sqrt(alpha) ) + real( v' * x );
        break;
        
    end
    
    if ~success,
        error( 'The second argument must be positive or negative semidefinite.' );
    end

end

% Copyright 2005-2016 CVX Research, Inc.
% See the file LICENSE.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.
