function op = project2DCone(x1, x2 )
% OP = project2DCone( y, x1, x2 )
%   represents the 2D point cone defined
%   by the vectors x1 and x2. x1 should be "left" of x2,
%   and the cone is defined as the region to the right
%   of x1 and to the left of x2.

error(nargchk(1,2,nargin));
if nargin < 2, u = []; end
%op = @proj_Rplus_impl;
% bugfix, March 2011:
op = @(varargin)proj_cone2(x1,x2,varargin{:});

function [v,x] = proj_cone2(x1,x2,y,t)
% "t" doesn't matter, since the only values are 0 and Inf
v = 0;
if size(y,2) > 1, y = y.'; end

% Assume that "x1" is active
n1 = [x1(2); -x1(1)]; % the normal direction
t1 = -y'*n1/(n1'*n1);


% Now assume "x2" is active:
n2 = [x2(2); -x2(1)];
t2 = -y'*n2/(n2'*n2);

switch nargin,
    case 3,
        if nargout == 2,
            error( 'This function is not differentiable.' );
        end
        if ( t1 > 0 ) && ( t2 < 0 )
            v = 0;
        else
            v = Inf;
        end
    case 4,
        if y'*x1 <= 0 && y'*x2 <= 0
            x = 0*y; v = 0;
            return;
        end
        
        p1 = y + t1*n1;
        p2 = y + t2*n2;
        
        % now determine which one is active:
        if p1'*x1 < 0
            % p1 cannot be active
            x = p2;
        elseif p2'*x2 < 0
            % p2 cannot be active
            x = p1;
        elseif ( t1 > 0 ) && ( t2 < 0 )
            % we are feasible!
            x = y;
        else
            % both could be active, so pick the best:  
            if norm( p1 - y ) < norm( p2 - y )
                x = p1;
            else
                x = p2;
            end
        end


	otherwise,
		error( 'Wrong number of arguments.' );
end


% TFOCS v1.3 by Stephen Becker, Emmanuel Candes, and Michael Grant.
% Copyright 2013 California Institute of Technology and CVX Research.
% See the file LICENSE for full license information.
