function op = proj_singleAffine( a, beta, ineq )
%PROJ_SINGLEAFFINE(a,beta)    Projection onto the affine set { x : a'*x == beta }
%    The parameter a may be a vector or matrix
%    of the same size as x. By default, beta is 0
%PROJ_SINGLEAFFINE(a,beta,ineq)
%    Projection onto the affine set { x : a'*x >= beta }
%       if ineq == 1, and onto { x : a'*x <= beta } if ineq == -1
%    Setting ineq == 0 (default) uses { x : a'*x == beta }
%
% For matrix variables, this interprets a'*x as a(:)'*x(:), e.g.,
% the standard dot product
%
%    OP = PROJ_SINGLEAFFINE returns an implementation of this projection.
%
% For more than one affine constraint, see proj_affine.m
%
% See also proj_boxAffine and proj_affine

error(nargchk(1,3,nargin));
if nargin < 2, beta = 0; end
if isempty(beta), beta = 0; end
if nargin < 3 || isempty(ineq), ineq = 0; end
op = @(varargin) proj_affine_internal(a,beta,ineq, varargin{:} );


function [v,x] = proj_affine_internal( a, beta, ineq, y, t )
v = 0;
switch nargin
    case 4
        if nargout == 2
            error('This function is not differentiable.');
        end
        % Check if we are feasible
        if abs( tfocs_dot(y,a) - beta ) > 1e-13
            v = Inf;
        end
    case 5
        dt  = tfocs_dot(a,y);
        if (ineq==0) || ( ineq==1 && dt < beta ) || (ineq==-1 && dt > beta)
            x   = y - ( dt - beta )/tfocs_dot(a,a) * a;
        else
            x   = y;
        end
    otherwise
        error( 'Wrong number of arguments.' );
end

% TFOCS v1.3 by Stephen Becker, Emmanuel Candes, and Michael Grant.
% Copyright 2013 California Institute of Technology and CVX Research.
% See the file LICENSE for full license information.
