function op = prox_dualize( dualProx, NEG )
%PROX_DUALIZE   Define a proximity function by its dual
%    OP = PROX_DUALIZE( dualOp ) returns an operator implementing the 
%    dual of the function dualProx. You can verify they are duals
%    via test_proxPair( dualOp, OP ).
%
%    OP = PROX_DUALIZE( dualOp, 'neg' )
%    OP = PROX_DUALIZE( dualOp, 'negative' )
%       will return the scaled dual of dualOp; that is,
%       dualOp(x) and OP(-x) are duals.
%       The negative is useful because this is the version TFOCS
%       expects for the SCD formulation.
%       For 1-homogenous functions (e.g. norms), this has no effect,
%       since ||x|| = ||-x||.
%
% Warning: if you can calculate the dual function explicitly,
%   it is likely more computationally efficient to do so, rather
%   than rely on this code. This code requires some tricks, some
%   of which can sometimes be expensive; also, it will call dualOp
%   so it is at least as slow as dualOp; and it may require high
%   precision from dualOp. This code can break down if dualOp
%   is not numerically stable.

if nargin < 2, NEG = ''; end
if strcmpi(NEG,'neg') || strcmpi(NEG,'negative')
    op = @(varargin)dualize(dualProx,-1,varargin{:} );
else
    op = @(varargin)dualize(dualProx,1,varargin{:} );
end

function [ v, x ] = dualize( dualProx, scale, x, t )
vec     = @(x) x(:);
myDot   = @(x,y) x(:)'*y(:);
if scale == -1
    x   = -x;
end
switch nargin,
    case 3
        if nargout == 2,
            error( 'This function is not differentiable.'  );
        else
            % This case is a bit tricky...
            %   If the function is non-differentiable, then standard exact
            %   penalty function results tell us that for a sufficiently
            %   small stepsize, we can remove the effect of smoothing.
            %   In other cases, we don't have an exact value, but we hope this
            %   is a reasonable approximation.
            
%             t       = 1e-15;
%             [~,x2]  = dualProx( x/t, 1/t );
%             v       = myDot(x,x2) - dualProx( x2 );
            
            % However, some functions break down when 1/t is huge
            % So we will slowly decrease it
            vOld    = Inf;
            t       = 1e-5;
            ok      = false;
            iter    = 0;
            while ~ok && t > eps
                [~,x2]  = dualProx( x/t, 1/t );
                v       = myDot(x,x2) - dualProx( x2 );
                if abs(v-vOld)/max( 1e-10, abs(v) ) < 1e-4
                    % due to exact penalty, we expect that
                    %   for t < t_cutoff, v=vOld up to machine accuracy
                    ok = true;
                else
                    t   = t/10;
                    vOld = v;
                    iter = iter + 1;
                    %fprintf('%d and v is %.2e\n', iter, v );
                end
            end
            
        end
        
    case 4
        % This is exact.
        [ignore,x2]  = dualProx( x/t, 1/t );
        x1      = x - t*x2; % Moreau's identity, equation (8.1) in the user guide
        v       = myDot(x1,x2) - dualProx( x2 );
        
        % If we think it is an indicator function, then round down to zero:
        if abs(v) < 100*eps,
            v  = 0;
        end
        x   = scale*x1;
        
    otherwise,
        error( 'Not enough arguments.' );
end

% TFOCS v1.3 by Stephen Becker, Emmanuel Candes, and Michael Grant.
% Copyright 2013 California Institute of Technology and CVX Research.
% See the file LICENSE for full license information.
