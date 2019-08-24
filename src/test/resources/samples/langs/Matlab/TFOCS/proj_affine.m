function op = proj_affine( A, b, R )
%PROJ_AFFINE(A, b)    Projection onto the affine set 
%    { x : A*x == b }
%
%   Warning! For large dimensions, this may be costly.
%   In this case, use proj_0 and explicitly seprate
%   out the affine term (this is the motivation behind
%   TFOCS). 
%
%   For efficiency, this function does a single costly
%   Cholesky decomposition when instatiated; subsequent
%   calls are cheap.
%PROJ_AFFINE(A, b, R)
%   uses the user-provided R for the Cholesky factorization
%   of A*A', i.e., R'*R = A*A' and R is upper triangular.
%
%   If A is a tight frame, e.g., A*A' = alpha*I for some
%   scalar alpha>0, then the projection is efficient, but it is
%   not automatically recognized. The user should
%   provide R = sqrt(alpha)*eye(m) (where A is m x n)
%   and then the code will be efficient.
%
%  N.B. If the system of equations is overdetermined,
%   then the set is just a single point.
%
% See also proj_boxAffine and proj_singleAffine

error(nargchk(2,3,nargin));
if nargin < 3
    if size(A,1) > 1e4
        warning('proj_affine:largeSize','Cholesky decomposition might take a large for such large matrices');
    end
    [R,p] = chol(A*A');
else
    p = 0;
    % Assuming that if user provides R, then it is not over-determiend
end
if p > 0
    % A*A' is rank deficient, i.e., system is over-determined
    % So, there is just a unique point
    warning('proj_affine:overdetermined','The system is over-determined so the set is a single point');
    xStar = A\b;
    op = @(varargin) proj_point( xStar, varargin{:} );
else
    op = @(varargin) proj_affine_internal( A, R, b, varargin{:} );
end

function [v,x] = proj_point( xStar, y, t )
v = 0;
switch nargin
    case 2
        if nargout == 2
            error('This function is not differentiable.');
        end
        % Check if we are feasible
        if norm( y - xStar ) > 1e-13
            v = Inf;
        end
    case 3
        % The projection is simple:
        x   = xStar;
    otherwise
        error( 'Wrong number of arguments.' );
end

function [v,x] = proj_affine_internal( A, R, b, y, t )
v = 0;
switch nargin
    case 4
        if nargout == 2
            error('This function is not differentiable.');
        end
        % Check if we are feasible
        if norm( A*y - b ) > 1e-13
            v = Inf;
        end
    case 5
        x = y + A'*( R\( R'\( b - A*y  )) );
    otherwise
        error( 'Wrong number of arguments.' );
end

% TFOCS v1.3 by Stephen Becker, Emmanuel Candes, and Michael Grant.
% Copyright 2013 California Institute of Technology and CVX Research.
% See the file LICENSE for full license information.
