function op = prox_boxDual(l,u,scale)
%PROX_BOXDUAL    Dual function of box indicator function { l <= x <= u }
%PROX_BOXDUAL(l,u)    Dual function of box indicator function { l <= x <= u }
%    If l or u is the empty matrix [], then the constraint is not
%    enforced (e.g. PROJ_BOXDUAL([],1) is the set { x <= 1 },
%       and PROJ_BOXDUAL(0) is the set { 0 <= x }  )
%    The parameters l and u may also be vectors or matrixes
%    of the same size as x.
%
%    OP = PROJ_BOXDUAL returns an implementation of this projection.
%
%   ... = PROJ_BOXDUAL( l, u, -1 )
%       will return an implementation of the projection composed
%       with the operator x --> -x.  This is the form that TFOCS
%       expects for the "conjnegeF" term.
%
%   See also proj_box, proj_Rplus

% the dual itself if g(x) = max( u*x, l*x )
%                         = { u*x, if x>=0;  v*x if x<0 }
% so the prox of the dual is
%   prox_{t*g}(x)   = { x - t*u, (value is u*x), if x >= u*t
%                     { x - t*l, (value is l*x), if x <= l*t
%                     { 0, (value is 1/t*x^2), otherwise


error(nargchk(1,3,nargin));
if nargin < 3, scale = 1;
else
    if ~isscalar(scale) || ( scale ~= 1 && scale ~= -1 )
        error('"scale" must be either +1 or -1');
    end
end
if nargin < 2, u = []; end
% check that l <= u
if ~isempty(l) && ~isempty(u)
    if ~all( l <= u )
        error('for box constraints, need  l <= u ');
    end
end
if isempty(l), l = -Inf; end
if isempty(u), u =  Inf; end

op = @(varargin)proj_RplusDual_impl(l,u,scale,varargin{:});

function [ v, xOut ] = proj_RplusDual_impl( l, u, scale,  x, t )
    if scale ~= 1
        x = scale*x;
    end
switch nargin,
	case 4,
        if nargout == 2,
            error( 'This function is not differentiable.' );
        end
        v = sum(sum(max( l.*x, u.*x )));
	case 5,
        xOut    = zeros( size(x) );
        if ~isempty(l)
            indx1 = find( x < t*l );
            if isscalar(l)
                xOut( indx1 ) = x( indx1 ) - t*l;
            else
                xOut( indx1 ) = x( indx1 ) - t*l( indx1 );
            end
        end
        if ~isempty(u)
            indx2 = find( x > t*u );
            if isscalar(u)
                xOut( indx2 ) = x( indx2 ) - t*u;
            else
                xOut( indx2 ) = x( indx2 ) - t*u( indx2 );
            end
        end
        % and implicity, if l/t < x < u/t, then xOut is 0
        
        v = sum(sum( max( l.*xOut, u.*xOut ) )); 
        
        % Bug fixed 3/23/2016, thanks to Carl Nettelblad for noticing
        if scale ~= 1
            xOut    = scale*xOut;
        end
	otherwise,
		error( 'Wrong number of arguments.' );
end


% TFOCS v1.3 by Stephen Becker, Emmanuel Candes, and Michael Grant.
% Copyright 2013 California Institute of Technology and CVX Research.
% See the file LICENSE for full license information.
