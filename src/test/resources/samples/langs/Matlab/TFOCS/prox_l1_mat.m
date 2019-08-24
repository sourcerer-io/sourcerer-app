function op = prox_l1_mat( q, nColumns, zeroID, useMatricized )

%PROX_L1_MAT    L1 norm, matricized in a special way
%    OP = PROX_L1_MAT( Q ) implements the nonsmooth function
%        OP(X) = norm(Q.*X,1) with constraints 
%    Q is optional; if omitted, Q=1 is assumed. But if Q is supplied,
%    then it must be a positive real scalar (or must be same size as X).
%
%    OP = PROX_L1_MAT( Q, nColumns )
%       takes the input vector X and reshapes it to have nColumns
%       and applies this prox to every column
%
%    OP = PROX_L1_MAT( Q, nColumns, zeroID )
%       if zeroID == true (it is false by default)
%       then after reshaping X, enforces that X(i,i) = 0
%
%    OP = PROX_L1_MAT( Q, nColumns, zeroID, useMatricized )
%       toggles between two algorithms if nColumns > 1.
%       If useMatricized is true (default), runs a variant algorithm
%       that is a bit faster (output should be the same).
%
% Often useful for sparse subpsace clustering (SSC)
%   See, e.g., https://github.com/stephenbeckr/SSC

% Mar 2018, Stephen.Becker@Colorado.edu

if nargin == 0
    q = 1;
elseif ~isnumeric( q ) || ~isreal( q ) ||  any( q < 0 ) || all(q==0) || numel( q ) ~= 1
    error( 'Argument must be positive.' );
end
if nargin < 2 || isempty( nColumns), nColumns = 1;
else assert( numel(nColumns) == 1 && nColumns >= 1 ); end
if nargin < 3 || isempty( zeroID ), zeroID = false; end
if nargin < 4 || isempty( useMatricized ), useMatricized = true; end

if zeroID && nColumns == 1
    warning('TFOCS:prox_l1_mat:zeroDiag',...
        'You requested enforcing zero diagonals but did not set nColumns>1 which is probably a mistake');
end

% This is Matlab and Octave compatible code
op = tfocs_prox( @(x)f(q,x), @(x,t)prox_f(q,nColumns,zeroID,useMatricized,x,t) , 'vector' );
end

% These are now subroutines, that are NOT in the same scope
function v = f(qq,x)
    v = norm( qq(:).*x(:), 1 );
end

function x = prox_f(qq,nColumns,zeroID,useMatricized,x,t) % stepsize is t
    tq = t .* qq; % March 2012, allowing vectorized stepsizes
    
    % 3/15/18, adding:
    if 3~=exist('shrink_mex','file')
        addpath( fullfile( tfocs_where, 'mexFiles' ) );
    end
    if 3==exist('shrink_mex','file') 
        shrink  = @(x) shrink_mex(x,tq);
    else
        % this is fast, but requires more memory
        shrink  = @(x) sign(x).*max( abs(x) - tq, 0 );
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
            Xsmall = shrink( Xsmall);
            for col = 1:nColumns
                X(col,col)  = 0;
                ind     = [1:col-1,col+1:size(X,1)];
                X(ind,col)  = Xsmall(:,col);
            end
        else
            for col = 1:nColumns
                ind     = [1:col-1,col+1:size(X,1)];
                x       = X(ind,col);
                x       = shrink( x);
                X(col,col)  = 0;
                X(ind,col)  = x;
            end
        end
        x   = X(:);
    else
        if nColumns > 1
            X   = reshape( x, [], nColumns );
            
            if useMatricized
                X = shrink( X );
            else
                for col = 1:nColumns
                    X(:,col) = shrink( X(:,col));
                end
            end
            x   = X(:);
        else
            x   = shrink( x );
        end
    end
end


