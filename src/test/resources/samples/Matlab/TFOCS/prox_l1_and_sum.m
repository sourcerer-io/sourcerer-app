function op = prox_l1_and_sum( q, b, nColumns, zeroID, useMatricized )

%PROX_L1_AND_SUM    L1 norm with sum(X)=b constraints
%    OP = PROX_L1_AND_SUM( Q ) implements the nonsmooth function
%        OP(X) = norm(Q.*X,1) with constraints 
%    Q is optional; if omitted, Q=1 is assumed. But if Q is supplied,
%    then it must be a positive real scalar (or must be same size as X).
%
%    OP = PROX_L1_AND_SUM( Q, B )
%       includes the constraints that sum(X(:)) == B
%       (Default: B=1)
%
%    OP = PROX_L1_AND_SUM( Q, B, nColumns )
%       takes the input vector X and reshapes it to have nColumns
%       and applies this prox to every column
%
%    OP = PROX_L1_AND_SUM( Q, B, nColumns, zeroID )
%       if zeroID == true (it is false by default)
%       then after reshaping X, enforces that X(i,i) = 0
%
%    OP = PROX_L1_AND_SUM( Q, B, nColumns, zeroID, useMatricized )
%       toggles between two algorithms if nColumns > 1.
%       If useMatricized is true (default), runs a variant algorithm
%       that is a bit faster (output should be the same).
%
% Often useful for sparse subpsace clustering (SSC)
%   See, e.g., https://github.com/stephenbeckr/SSC

% Nov 2017, Stephen.Becker@Colorado.edu

if nargin == 0
    q = 1;
elseif ~isnumeric( q ) || ~isreal( q ) ||  any( q < 0 ) || all(q==0) || numel( q ) ~= 1
    error( 'Argument must be positive.' );
end
if nargin < 2 || isempty(b), b = 1; else, assert( numel(b) == 1 ); end
if nargin < 3 || isempty( nColumns), nColumns = 1;
else assert( numel(nColumns) == 1 && nColumns >= 1 ); end
if nargin < 4 || isempty( zeroID ), zeroID = false; end
if nargin < 5 || isempty( useMatricized ), useMatricized = true; end

if zeroID && nColumns == 1
    warning('TFOCS:prox_l1_and_sum:zeroDiag',...
        'You requested enforcing zero diagonals but did not set nColumns>1 which is probably a mistake');
end

% This is Matlab and Octave compatible code
op = tfocs_prox( @(x)f(q,x), @(x,t)prox_f(q,b,nColumns,zeroID,useMatricized,x,t) , 'vector' );
end

% These are now subroutines, that are NOT in the same scope
function v = f(qq,x)
    v = norm( qq(:).*x(:), 1 );
end

function x = prox_f(qq,b,nColumns,zeroID,useMatricized,x,t) % stepsize is t
    tq = t .* qq; % March 2012, allowing vectorized stepsizes
    
    % 3/15/18, adding:
    if 3~=exist('shrink_mex','file')
        addpath( fullfile( tfocs_where, 'mexFiles' ) );
    end
    if 3==exist('shrink_mex','file') 
        shrink  = @(x) shrink_mex(x,tq);
        shrink_nu = @(x,nu) shrink_mex(x,tq,nu);
    else
        % this is fast, but requires more memory
        shrink  = @(x) sign(x).*max( abs(x) - tq, 0 );
        shrink_nu = @(x,nu) shrink(x-nu);
    end
    
    if zeroID && nColumns > 1
        X   = reshape( x, [], nColumns );
        n   = size(X,1);
        if nColumns > n
            error('Cannot zero out the diagonal if columns > rows');
        end
        if useMatricized
            Xsmall = zeros( n-1, nColumns );
            for col = 1:nColumns
                ind     = [1:col-1,col+1:size(X,1)];
                Xsmall(:,col)   = X(ind,col);
            end
            Xsmall = prox_l1sum_matricized( Xsmall, tq, b, shrink_nu );
            for col = 1:nColumns
                X(col,col)  = 0;
                ind     = [1:col-1,col+1:size(X,1)];
                X(ind,col)  = Xsmall(:,col);
            end
        else
            for col = 1:nColumns
                ind     = [1:col-1,col+1:size(X,1)];
                x       = X(ind,col);
                x       = prox_l1sum( x, tq, b, shrink_nu );
                X(col,col)  = 0;
                X(ind,col)  = x;
            end
        end
        x   = X(:);
    else
        if nColumns > 1
            X   = reshape( x, [], nColumns );
            
            if useMatricized
                X = prox_l1sum_matricized( X, tq, b, shrink_nu );
            else
                for col = 1:nColumns
                    X(:,col) = prox_l1sum( X(:,col), tq, b, shrink_nu );
                end
            end
            x   = X(:);
        else
            x   = prox_l1sum( x, tq, b, shrink_nu );
        end
    end
end



% Main algorithmic part: if x0 is length n, takes O(n log n) time
function x = prox_l1sum( x0, lambda, b, shrink_nu )

    brk_pts = sort( [x0-lambda;x0+lambda], 'descend' );

    xnu     = @(nu) shrink_nu( x0 , nu );
    h       = @(x) sum(x) - b; % want to solve h(nu) = 0

    % Bisection
    lwrBnd       = 0;
    uprBnd       = length(brk_pts) + 1;
    iMax         = ceil( log2(length(brk_pts)) ) + 1;
    PRINT = false; % set to "true" for debugging purposes
    if PRINT
        dispp = @disp;
        printf = @fprintf;
    else
        dispp = @(varargin) 1;
        printf = @(varargin) 1;
    end
    dispp(' ');
    for i = 1:iMax
        if uprBnd - lwrBnd <= 1
            dispp('Bounds are too close; breaking');
            break;
        end
        j = round( (lwrBnd+uprBnd)/2 );
        %printf('j is %d (bounds were [%d,%d])\n', j, lwrBnd,uprBnd ); %
        if j==lwrBnd
            dispp('j==lwrBnd, so increasing');
            j = j+1;
        elseif j==uprBnd
            dispp('j==uprBnd, so increasing');
            j = j-1;
        end
        
        a   = brk_pts(j);
        x   = xnu(a);  % the prox
        p   = h(x);
        
        if p > 0
            uprBnd = j;
        elseif p < 0
            lwrBnd = j;
        end
        if PRINT
            % Don't rely on redefinition of printf,
            % since then we would still calculate find(~x)
            % which is slow
            printf('i=%2d, a = %6.3f, p = %8.3f, zeros ', i, a, p );
            if n < 100, printf('%d ', find(~x) ); end
            printf('\n');
        end
    end
    
    % Now, determine linear part, which we infer from two points.
    % If lwr/upr bounds are infinite, we take special care
    % e.g., we make a new "a" slightly lower/bigger, and use this
    % to extract linear part.
    if lwrBnd == 0
        a2 = brk_pts( uprBnd );
        a1 = a2 - 10; % arbitrary
        aBounds = [a1,a2];
    elseif uprBnd == length(brk_pts) + 1
        a1 = brk_pts( lwrBnd );
        a2 = a1 + 10; % arbitrary
        aBounds = [a1,a2];
    else
        % In general case, we can infer linear part from the two break points
        a1 = brk_pts( lwrBnd );
        a2 = brk_pts( uprBnd );
        aBounds = [a1,a2];
    end
    
    % Now we have the support, find exact value
    x       = xnu(( aBounds(1)+aBounds(2))/2 );  % to find the support
    supp    = find(x);

    sgn     = sign(x);
    nu      = ( sum(x0(supp) - lambda*sgn(supp) ) - b )/length(supp);
    
    x   = xnu( nu );

end


% This variant can handle several columns at once,
% and it takes exactly log2(n) iterations, as it doesn't stop early
%   since different columns might stop at different steps and that's
%   not easy to detect efficiently.
function x = prox_l1sum_matricized( x0, lambda, b, shrink_nu )

    brk_pts = sort( [x0-lambda;x0+lambda], 'descend' );
    
    
    xnu     = @(nu) shrink_nu( x0 , nu );
    
    h       = @(x) sum(x) - b; % want to solve h(nu) = 0

    nCols        = size( x0, 2 ); % allow matrices
    LDA          = size( brk_pts, 1 );
    offsets      = (0:nCols-1)*LDA;%i.e., [0, LDA, 2*LDA, ... ];
    
    lwrBnd       = zeros(1,nCols);
    uprBnd       = (length(brk_pts) + 1)*ones(1,nCols);
    iMax         = ceil( log2(length(brk_pts)) ) + 1;

    for i = 1:iMax

        j = round(mean([lwrBnd;uprBnd]));
        ind = find( j==lwrBnd );
        j( ind ) = j( ind ) + 1;
        ind = find( j==uprBnd );
        j( ind ) = j( ind ) - 1;
        
        a   = brk_pts(j+offsets); % need the offsets to correct it here
        x   = xnu(a);  % the prox
        p   = h(x);
        
        ind = find( p > 0 );
        uprBnd(ind) = j(ind);
        ind = find( p < 0 );
        lwrBnd(ind) = j(ind);

    end

    
    [a1,a2]     = deal( zeros(1,nCols) );
    ind = find( lwrBnd == 0 );
    a2(ind) = brk_pts( uprBnd(ind) + offsets(ind) );
    a1(ind) = a2(ind) - 10;
    ind2 = ind;
    
    ind = find( uprBnd == size(brk_pts,1) + 1 );
    a1(ind) = brk_pts( lwrBnd(ind) + offsets(ind) );
    a2(ind) = a1(ind) + 10;
    
    indOther = setdiff( 1:nCols, [ind2,ind] );
    a1(indOther)    = brk_pts( lwrBnd(indOther) + offsets(indOther) );
    a2(indOther)    = brk_pts( uprBnd(indOther) + offsets(indOther) );
    
    a  = mean( [a1;a2] );
    x       = xnu( a );
    
    nu      = zeros(1,nCols);
    sgn     = sign(x);
    for col = 1:nCols
        supp    = find( sgn(:,col) );
        nu(col)      = ( sum(x0(supp,col) - lambda*sgn(supp,col) ) - b )/length(supp);
    end
    x   = xnu( nu );

end
