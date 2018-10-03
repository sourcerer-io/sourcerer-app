function [ dbCA, cones, dir, Q, P, dualized ] = eliminate( prob, destructive, can_dual )
if nargin < 3, can_dual = nargout >= 6; end
if nargin < 2, destructive = false; end

% For the problem
%
%    minimize c' * x + d
%    s.t.     y : A * x + b == 0
%             x \in K
%
% The Lagrangian is
%   
%  L(x,y,z) = c' * x + d - y' * ( A x + b ) - z' * x
%
%                            [ - d  b' 0 ]   [ 1 ]
%            = - [ 1, x' ] * [ - c  A' I ] * [ y ]
%                                            [ z ]
%
% This function provides a smaller [ d, b' ; c, A' ] with no more nonzeros
% that solves an equivalent problem. The original x and y can be recovered
% from the reduced xx and yy by Q*[1;xx] and P*[1;-yy], respectively.

[ dbCA, cones, dir, Q, P ] = extract( prob, destructive );
dualized = false;
if size( dbCA, 1 ) == 1, 
    return; 
end

%
% Negate the objective so that the transformation matrices P and Q are
% properly formed.
%

dbCA(:,1) = -dbCA(:,1);
if ~issparse( dbCA ),
    dbCA = sparse( dbCA );
end

for pass = 1 : 2,

    if pass == 1 || dualized,
        n_tot = 0;
        nn  = size(dbCA,1);
        rsv = sparse( 1, 1, 1, nn, 1 );
        nng = sparse( nn, 1 );
        for k = 1 : length( cones ),
            temp = cones(k).indices;
            n_tot = n_tot + numel(temp);
            temp = sparse( temp, 1, 1, nn, 1 );
            rsv = rsv + temp;
            if isequal( cones(k).type, 'nonnegative' ),
                nng = nng + temp;
            elseif can_dual && strncmp( cones(k).type, 'i_', 2 ),
                can_dual = false;
            end
        end
        rsv   = full( rsv );
        nng   = full( nng );
        ndxs  = ( 1 : nn )';
        nold  = nn;
    end

    cc   = dbCA( :, 1 );
    rcnt = sum( dbCA ~= 0, 2 );
        
    % In the first pass, we don't eliminate columns which have inequality
    % structure to them, so that we can make the best decision as to
    % whether or not to convert the problem to dual standard form. Exempted
    % from this are columns with trivial xi = xj constraints, where xi is free.
    if pass == 1,
        trivs = sum( dbCA(rsv==0,:) ~= 0, 1 ) == 1 & sum( dbCA(rsv~=0,:) ~= 0, 1 ) - ( dbCA( 1, : ) ~= 0 ) == 1;
        ineqs = full(any(dbCA(rsv~=0&rcnt==1,:),1)) & full(~trivs);
        ineqs = +ineqs;
    else % if dualized,
        ineqs = zeros(1,size(dbCA,2));
    end
    ineqs(1) = 1;
    
    while true,
        
        success = false;
        
        %
        % STEP 1: Look for free or nonnegative variables that do not appear
        % in any constraints. Unconstrained variables that also appear in
        % the objective are unbounded, as are nonnegative variables that
        % appear there with the right sign. Otherwise their values might
        % as well be zero. If we have multiple unbounded variables, keep
        % all but one so that the solver can still see this happen.
        %
        % Eliminated for now. Frankly, my suspicion is that this happens
        % very infrequently, and this code seems to have been the source
        % of bugs in the past.
        %
        
        if 0,
            rows = ( rcnt == ( cc ~= 0 ) ) & ( ~rsv | nng );
            nnzr = nnz( rows );
            if nnzr > 0,
                csgn = 1 - 2 * dualized;
                celm = csgn * cc( rows, 1 );
                celm( nng(rows) & celm < 0 ) = 0;
                nnzc = nnz( celm );
                if nnzc > 1 || nnzr > nnzc,
                    success = true;
                    if nnzc,
                        cnrm = norm( celm );
                        ndxq = find( rows );
                        ndxq = ndxq( celm ~= 0 );
                        ndxq = ndxq( 1 );
                        Q( :, ndxq ) = Q( :, rows ) * ( celm / cnrm );
                        dbCA( ndxq, 1 ) = csgn * cnrm; %#ok
                        rows( ndxq ) = 0;
                    end
                    rowX = ~rows;
                    dbCA = dbCA( rowX, : );
                    rsv  = rsv ( rowX, : );
                    nng  = nng ( rowX, : );
                    ndxs = ndxs( rowX, : );
                    Q    =    Q( :, rowX );
                end
            end
        end
        
        %
        % STEP 2: Look for columns which differ only by a constant factor.
        % These correspond to redundant equality constraints. These occur
        % often enough as as consequence of our tranformation method, and
        % they cause problems in solvers, so we must eliminate them. Of
        % course, if there are more complex linear dependencies in the
        % equality constraints, we can't do anything about that.
        %
        
        [ xR, dbCA ] = cvx_bcompress( dbCA, 'full', 1 );
        if size( xR, 1 ) ~= size( xR, 2 ),
            success = true;
            P       = P * cvx_invert_structure( xR );
            ineqs   = ( xR * ineqs(:) )' ~= 0;
            ineqs   = +ineqs;
        end
        
        while true,
            
            %
            % STEP 3: Look for variables that we can eliminate without
            % increasing fill-in. This means looking for rows or columns
            % with only 1, 2, or (in some cases) 3 nonzeros.
            %
            
            [ rows, cols ] = cvx_eliminate_mex( dbCA, 1, rsv, ineqs );
            if ~any( rows ), break; end
            success = true;
            rows = rows ~= 0;
            cols = cols ~= 0;
            rowX = ~rows;
            colX = ~cols;
            
            %
            % [ x1^T x2^T ] [ C1 A11 A12 ] [ 1  ]
            %               [ C2 A21 A22 ] [ y1 ] = 0
            %                              [ y2 ]
            %
            % [ x1^T x2^T ] = x1^T [ I -A12*A22i ]
            %
            % [ G Y1^T Y2^T ] = [ G Y1^T ] [ I  0  -C2'*A22i'  ]
            %                              [ 0  I  -A21'*A22i' ]
            
            %
            A11  = dbCA( rowX, colX );
            A12  = dbCA( rowX, cols );
            A21  = dbCA( rows, colX );
            A22  = dbCA( rows, cols );
            if ( size( A22, 1 ) ~= size( A22, 2 ) || nnz( A22 ) ~= size( A22, 1 ) ),
                error( 'There seems to be an error in the CVX presolver routine.\nPlease report this to the authors; and if possible, include the\ncvx model and data that gave you this error.', 1 ); %#ok
            end
            [ ii, jj, vv ] = find( A22 );
            A22i  = sparse( jj, ii, 1.0 ./ vv );
            temp  = - A22i * A21;
            P     = P( :, colX ) + P( :, cols ) * temp;
            temp  = - A12 * A22i;
            Q     = Q( :, rowX ) + Q( :, rows ) * temp';
            dbCA  = A11 + temp * A21;
            rsv   =   rsv( rowX, : );
            nng   =   nng( rowX, : );
            ndxs  =  ndxs( rowX, : );
            ineqs = ineqs( :, colX );
            
        end
        
        if ~success,
            break;
        end
        
        cc   = dbCA( :, 1 );
        rcnt = sum( dbCA ~= 0, 2 );
        
    end
    
    if pass == 2 || isempty(cones) || ~can_dual,
        break;
    end
    
    %
    % Check to see if dualization will result in smaller problem
    %
    ineqs(1) = 0; rsv(1) = 0;
    n_save = nnz(cvx_eliminate_mex(dbCA,1,rsv,zeros(size(ineqs))));
    % n_save = nnz(sum(dbCA(:,ineqs~=0)~=0,1)==1+(dbCA(1,ineqs~=0)~=0));
    n_ineq = nnz(any(dbCA(rsv&rcnt==(cc~=0)+1,:)));
    rsv(1) = 1; ineqs(1) = 1; %#ok
    [n1,m1] = size(dbCA);
    m_pri = m1 - n_save - 1;
    n_pri = n1 - n_save - 1;
    m_dua = n1 - n_ineq - 1;
    n_dua = nnz( rsv ) + m1 - n_ineq - 1;
    if ( ( m_pri > n_pri ) || ( m_pri * m_pri * n_pri > m_dua * m_dua * n_dua ) ) && ( m_dua <= n_dua ),
        ndxs = full(sparse(ndxs,1,1:n1));
        PP = cell(2,length(cones));
        n_cur = m1;
        for k = 1 : length(cones),
            temp = cones(k).indices;
            [nn,nv] = size(temp);
            temp = reshape(ndxs(temp),size(temp));
            switch cones(k).type,
                case 'semidefinite',
                    nt = 0.5*(sqrt(8*nn+1)-1);
                    SS = 'symmetric';
                case 'hermitian-semidefinite',
                    nt = sqrt(nn);
                    SS = 'hermitian';
                case 'exponential',
                    SS = sparse(inv([0,-1,0;-1,0,0;0,0,exp(1)]));
                    SS = cvx_replicate_structure(SS,nv);
                otherwise,
                    SS = [];
            end
            PP{k} = sparse(1:numel(temp),max(temp,1),temp~=0,numel(temp),n1);
            if ~isempty(SS),
                if ischar(SS),
                    SS = cvx_create_structure([nt,nt,nv],SS);
                    SS = SS * SS';
                end
                PP{k} = SS * PP{k};
            end
            cones(k).indices = reshape(n_cur+1:n_cur+nn*nv,nn,nv);
            n_cur = cones(k).indices(end);
        end
        dbCA  = vertcat(dbCA',PP{:});
        dir   = -dir;
        tmp   = Q; Q = P; P = tmp;
        nold  = size(dbCA,1);
        Q(:,nold) = 0;
        dualized = true;
    end
    
end

%
% Return the objective back to normal.
%

if dualized,
    P = -P;
    P(:,1) = -P(:,1);
else
    dbCA(:,1) = -dbCA(:,1);
end

%
% Move the cone indices to their new locations
%

ndxs = full( sparse( ndxs, 1, 1 : length( ndxs ), nold, 1 ) );
tt = zeros(1,length(cones));
for k = 1 : length( cones ),
    temp = ndxs(cones(k).indices);
    if all(temp),
        temp = reshape( temp, size(cones(k).indices) );
    else
        temp = nonzeros(temp);
        temp = reshape( temp, 1, length(temp) );
    end
    tt(k) = isempty(temp);
    cones(k).indices = temp;
end
if any(tt),
    cones(tt~=0) = [];
end

% Copyright 2005-2016 CVX Research, Inc.
% See the file LICENSE.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.
