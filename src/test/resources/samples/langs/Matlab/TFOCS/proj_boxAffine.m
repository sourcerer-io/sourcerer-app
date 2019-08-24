function op = proj_boxAffine( a, l, u, alpha )
%PROJ_BOXAFFINE(a,l,u,alpha)    Projection onto the box { l <= x <= u } intersected
%    with the constraint a'*x == alpha
%    If l or u is the empty matrix [], then the constraint is not
%    enforced. "a" must be included (otherwise, use proj_box.m).
%    The parameters l and u may also be vectors or matrixes
%    of the same size as x.
%    The offset "alpha" is optional (default is 0)
%
%    OP = PROJ_BOXAFFINE returns an implementation of this projection.
%
% See also proj_box, proj_affine, proj_singleAffine, prox_boxDual
error(nargchk(3,4,nargin));
if isempty(l), l = -Inf(size(a)); end
if isempty(u), u = Inf(size(a)); end
if nargin < 4 || isempty(alpha), alpha = 0; end
% % Not the most efficient, but least amount of coding work:
% if isequal(size(l),[1,1]) && numel(a) > 1
%     l   = l*ones(size(a));
% end
% if isequal(size(u),[1,1]) && numel(a) > 1
%     u   = u*ones(size(a));
% end
op = @(varargin) proj_box_affine(a,l,u, alpha, varargin{:} );


function [v,x] = proj_box_affine( a, l, u, alpha, y, t )
v = 0;
switch nargin
    case 5
        if nargout == 2
            error('This function is not differentiable.');
        end
        % Check if we are feasible
        if any( y < l ) || any( y > u ) || abs( tfocs_dot(y,a) ) > 1e-13
            v = Inf;
        end
    case 6
        scalarL = ( numel(l) == 1 );
        scalarU = ( numel(u) == 1 );
        
        n           = length(y);
        if numel(y) > n
            % It should work, but no 100% guarantees
%             warning('TFOC:proj_boxAffine','Not extensively tested for matrix inputs; use at your own risk!'); 
            n   = numel(y);
        end
        projBox     = @(x) max( l, min( u, x ) );
        % Turning points for constraints = l (l for lower)
        T1 = (y-l)./a;
        % Turning points for constraints = u (u for upper)
        T2 = (y-u)./a;
        T = sort(union(T1(:),T2(:)));
        lwrBound = 1;
        uprBound = 2*n;
        for i = 1:ceil(log2(2*n))
            indx    = round( (lwrBound+uprBound)/2 );
            beta    = T(indx);
            
            % Our trial solution
            x       = projBox( y - beta*a );
            % Refine beta on the support (ignore constraints): see if it satisifies constraints
            S       = find( x > l & x < u );
            S1      = x==l;
            S2      = x==u;

            % Given the fixed points, we subtract these off, and resolve the
            % plain affine projection problem on the active set
            % The affine projection solun is always x = y - betaEst*a
            %   for some betaEst.
            
%             betaEst = (a(S)'*y(S) + a(S2)'*u(S2) + a(S1)'*l(S1) )/(a(S)'*a(S));
            % Or, so that we can allow u and l to be scalars,
            if scalarL, al = sum(a(S1))*l; else al = a(S1)'*l(S1); end
            if scalarU, au = sum(a(S2))*u; else au = a(S2)'*u(S2); end
            betaEst = (a(S)'*y(S) + au + al - alpha )/(a(S)'*a(S));
            
            
            % Check if bestEst is in the admissible range
            % e.g. if betaEst > beta, is it less than T(indx+1)? and vice-versa
            if betaEst > beta
                if indx == 2*n || betaEst < T(indx+1)
                    break;
                else
                    lwrBound = indx + 1; % we need to increase beta
                end
            else
                if indx == 1 || betaEst > T(indx-1)
                    break;
                else
                    uprBound = indx - 1; % we need to decrease beta
                end
            end
        end
        x       = projBox( y - betaEst*a );
        S       = find( x > l & x < u );
        S1      = x==l;
        S2      = x==u;
%         betaEst = (a(S)'*y(S) + a(S2)'*u(S2) + a(S1)'*l(S1) )/(a(S)'*a(S));
        % Or, so that we can allow u and l to be scalars,
        if scalarL, al = sum(a(S1))*l; else al = a(S1)'*l(S1); end
        if scalarU, au = sum(a(S2))*u; else au = a(S2)'*u(S2); end
        betaEst = (a(S)'*y(S) + au + al -alpha )/(a(S)'*a(S));
        x       = projBox( y - betaEst*a );
    otherwise
        error( 'Wrong number of arguments.' );
end

% TFOCS v1.3 by Stephen Becker, Emmanuel Candes, and Michael Grant.
% Copyright 2013 California Institute of Technology and CVX Research.
% See the file LICENSE for full license information.
