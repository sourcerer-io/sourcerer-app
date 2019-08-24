function op = proj_conic()
%PROJ_CONIC
%   Returns an operator implementing projection onto
%   the second order cone, aka (real) Lorentz cone
%   aka ice-cream cone
%   That is,
%       { x : norm( x(1:end-1) , 2) <= x(end) }
%
%   The cone is often written as
%       { (x,t) : ||x|| <= t }
%   so note that in this implementation, "t" is
%   inferred from the final coordinate of x.
%
% Contributed by Joself Salmon 2013

op = @proj_conic_impl;

function [ v, x ] = proj_conic_impl( x, t )
v = 0;
[n,m]=size(x);
sum_part=sqrt( sum(x(1:n-1).^2) );
xn=(x(n));

switch nargin,
	case 1,
		if nargout == 2
			error( 'This function is not differentiable.' );
        elseif ( (sum_part)>xn )            
            v = Inf;        
        end
	case 2,

        if ( ((sum_part) -abs(xn))> 0 )
            x=1/2*(1+xn/sum_part)*[x(1:n-1);sum_part];
        
        elseif ( (sum_part)<(xn) )
            x=x;            
        elseif ( (sum_part)<(-xn) )
            x=zeros(n,m);
        
        end
                    
	otherwise,
		error( 'Not enough arguments.' );
end
% TFOCS v1.3 by Stephen Becker, Emmanuel Candes, and Michael Grant.
% Copyright 2013 California Institute of Technology and CVX Research.
% See the file LICENSE for full license information.
