function op = prox_l1( q )

%PROX_L1    L1 norm.
%    OP = PROX_L1( q ) implements the nonsmooth function
%        OP(X) = norm(q.*X,1).
%    Q is optional; if omitted, Q=1 is assumed. But if Q is supplied,
%    then it must be a positive real scalar (or must be same size as X).
% Dual: proj_linf.m

% Update Feb 2011, allowing q to be a vector
% Update Mar 2012, allow stepsize to be a vector

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

% The following commented code works fine in Matlab,
%   but doesn't work in Octave due to different conventions on nesting
%   functions. We keep in in the comments since it may be useful
%   as an example of building a prox function

% op = tfocs_prox( @f, @prox_f , 'vector' ); % Allow vector stepsizes
% function v = f(x)
%     v = norm( q(:).*x(:), 1 );
% end
% function x = prox_f(x,t)  
%     tq = t .* q; % March 2012, allowing vectorized stepsizes
%     s  = 1 - min( tq./abs(x), 1 );
%     x  = x .* s;
% end
% end % end of main file

% This is Matlab and Octave compatible code
op = tfocs_prox( @(x)f(q,x), @(x,t)prox_f(q,x,t) , 'vector' );
end

% These are now subroutines, that are NOT in the same scope
function v = f(qq,x)
    v = norm( qq(:).*x(:), 1 );
end

function x = prox_f(qq,x,t)  
    tq = t .* qq; % March 2012, allowing vectorized stepsizes
    s  = 1 - min( tq./abs(x), 1 );
    x  = x .* s;
end



% TFOCS v1.3 by Stephen Becker, Emmanuel Candes, and Michael Grant.
% Copyright 2013 California Institute of Technology and CVX Research.
% See the file LICENSE for full license information.
