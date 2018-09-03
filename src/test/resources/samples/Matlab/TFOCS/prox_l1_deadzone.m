function op = prox_l1_deadzone( q, epsilon )

%PROX_L1_DEADZONE    L1 norm with deadzone [-eps,eps]
%    OP = PROX_L1_DEADZONE( q, eps ) implements the nonsmooth function
%        OP(X) = q*sum_i max(0,x-eps)+max(0,-x-eps) = q*sum_i
%        max(0,|x|-eps)
%    Q is optional; if omitted, Q=1 is assumed. But if Q is supplied,
%    then it must be a positive real scalar (or must be same size as X).
%

% New March 2 2016

if nargin == 0,
	q = 1;
elseif ~isnumeric( q ) || ~isreal( q ) ||  any( q < 0 ) || all(q==0) %|| numel( q ) ~= 1
    if q==0
        op = prox_0;
        warning('TFOCS:zeroQ','q=0 so returning the proximal operator for the zero function');
        return;
    else
        error( 'Argument must be positive.' );
    end
end

% This is Matlab and Octave compatible code
op = tfocs_prox( @(x)f(q, epsilon,x), @(x,t)prox_f(q, epsilon,x,t) , 'vector' );
end

% These are now subroutines, that are NOT in the same scope
function v = f(qq,epsilon, x)
    v = sum( qq(:).*max(0,abs(x(:))-epsilon), 1 );
end

function x = prox_f(qq,epsilon, x,t)  
% p = x if |x|<eps,
% p = sign(x)*eps if eps < |x| < tq
% p = sign(x)*( |x| - (eps+tq) ) if |x| > tq
% i.e., if |x|>eps,  p = sign(x).*max( |x|-tq, eps )
    tq = t .* qq; 
    x  = sign(x).*( abs(x).*( abs(x)<epsilon ) + max(abs(x)-tq, epsilon).*( abs(x)>= epsilon) );
end



% TFOCS v1.3 by Stephen Becker, Emmanuel Candes, and Michael Grant.
% Copyright 2013 California Institute of Technology and CVX Research.
% See the file LICENSE for full license information.
