function op = proj_l2( q, b, A, opts)

%PROJ_L2   Projection onto the scaled 2-norm ball.
%    OP = PROJ_L2( Q ) returns an operator implementing the 
%    indicator function for the 2-norm ball of size q,
%    { X | norm( X, 2 ) <= q }. Q is optional; if omitted,
%    Q=1 is assumed. But if Q is supplied, it must be a positive
%    real scalar.
%       (There is experimental support for the case Q=diag(q) with q_i > 0,
%        which requires a 1-dimensional search. This has not been
%        carefully tested. In this case, the set is
%        { X | norm( X./q, 2 ) <= 1  }  )
%
%    OP = PROJ_L2( Q, b ) represents the shifted set
%     { X | norm( X - b, 2 ) <= q }
%
%    OP = PROJ_L2( Q, b, A ) represents the shifted-and-scaled set
%     { X | norm( A*X - b, 2 ) <= q }
%     Warning: this requires the SVD of A and a one-dimensional
%     root-finding procedure, so it can be slow for large dimensional
%     problems. You may want to use TFOCS_SCD.m and explicitly declare
%     the linear operator (and offset/shift) which will avoid requiring
%     the SVD (although if you can afford the SVD, calling this function
%     with "A" may be faster since it can lead to fewer iterations in
%     the overall optimization algorithm).
%    OP = PROJ_L2( Q, b, A, opts )
%     allows the user to fine-tine the settings of the 1-D search
%     by changing parameters in the structure "opts"
%
%   If q=0, you should use proj_0 instead since it can be more efficient.
%
% Dual: prox_l2.m
% See also: prox_l2.m

% June 16 2014, adding support for offset "b" and scaling "A"

if nargin == 0,
	q = 1;
elseif ~isnumeric( q ) || ~isreal( q )
	error( 'Argument must be a real scalar.' );
end
if nargin < 2 || isempty(b)
    b = 0;
end
if numel(q) == 1
    if q==0, error('Argument "q" must be non-zero: use proj_0.m instead'); end
    if q <= 0, error('Argument "q" must be positive'); end
    if nargin >= 3
        % Complicated case. We need SVD(A)
        if nargin < 4, opts = []; end
        disp('Now computing SVD of A. Please wait...');
        [U,S,V] = svd(A,0);
        disp('... done');
        proj_l2_Aq(); % clear dual variable history
        op = @(varargin)proj_l2_Aq( q, b, U,S,V,opts,varargin{:} );       
    else
        op = @(varargin)proj_l2_q( q, b, varargin{:} );
    end
else
    if any( abs(q) < 10*eps ), error('Weight "q" must be nonzero'); end
    warning('TFOCS:experimental','Using experimental feature of TFOCS');
    if nargin>=3
        error('If q is a vector, cannot also have an arbitrary matrix scaling');
    end
    op = @(varargin)proj_l2_qVec( q, b, varargin{:} );
end
end% end of sub-routine

% -- Subfunctions --
function [ v, x ] = proj_l2_q( q, b,  x, t )
v = 0;
switch nargin,
	case 3,
		if nargout == 2,
			error( 'This function is not differentiable.' );
		elseif norm( x(:), 'fro' ) > q, % GKC fix 2013 (for > 2D arrays)
			v = Inf;
		end
	case 4,
        x   = x - b;
        nrm = norm(x(:),'fro'); % fixing, Feb '11, and GKC fix 2013
        if nrm > q
            x = x .* ( q / nrm );
        end
        x   = x + b;
	otherwise,
		error( 'Not enough arguments.' );
end
end% end of sub-routine

% -- experimental version for when q is a vector --
function [ v, x ] = proj_l2_qVec( q, b,  x, t )
v = 0;
switch nargin,
	case 3,
		if nargout == 2,
			error( 'This function is not differentiable.' );
		elseif norm( x./q, 'fro' ) > 1,
			v = Inf;
		end
	case 4,
        x   = x - b;
        nrm = norm(x./q,'fro');
        if nrm > 1

            % We know x is of the form x0./( 1 + lambda*D2 )
            %   for some lambda > 0, but we don't have an easy
            %   way to know what lambda is.  So, treat this as
            %   a 1D minimization problem to find lambda.
            D = 1./(q);
            D2 = D.^2;
            Dx = D.*x;
            
%             lMax  = max( abs(x./D2) )*sqrt(numel(x));
            lMax  = 1.2*norm( abs(x./D2),'fro'); % a tighter bound
            fmin_opts  = optimset( 'TolX', 1e-12 );
%             MaxFunEvals: 500
%                    MaxIter:
            [lOpt,val,exitflag,output]    = ...
                fminbnd( @(l) (norm(Dx./(1+l*D2),'fro')-1)^2, 0, lMax,fmin_opts);
            if val > 1e-3, error('Proj_l2 failed to converge'); end
            x       = x./( 1 + lOpt*D2 );
        end
        x   = x + b;
        
	otherwise,
		error( 'Not enough arguments.' );
end
end% end of sub-routine

function [ v, x ] = proj_l2_Aq( q, b, U,S,V,opts, x, t )
persistent dualVariable
if nargin==0, dualVariable = []; return; end
if isempty(dualVariable), dualVariable = 0; end % should be negative

v = 0;
switch nargin,
	case 7,
		if nargout == 2,
			error( 'This function is not differentiable.' );
		elseif norm( x(:), 'fro' ) > q
			v = Inf;
		end
	case 8
        opts = struct('lambda0',.999*dualVariable);
        [x,projIter,dualVariable] = fastProjection(U,S,V,x,b,q,opts);
	otherwise,
		error( 'Not enough arguments.' );
end
end% end of sub-routine


%% --------- The routine for the scaled case {x: ||Ax-b||<= q}

function [x,k,l] = fastProjection( U, S, V, y, b, epsilon, opts )
% [x,niter,lambda] = fastProjection(U, S, V, y, b, epsilon, opts )
%
% minimizes || x - y ||
%   such that || Ax - b || <= epsilon
%
% where USV' = A (i.e the SVD of A)
%
% OPTS is a structure with the following (optional) parameters:
%   .lambda0    Initial guess for the Lagrange parameter (should be negative)
%   .disp       If true, displays some output. Default: false
%   .tol        Tolerance. Default is 1e-8*epsilon
%   .maxit      Maximum number of iterations for Newton's method
%
% Warning: for speed, does not calculate A(y) to see if x = y is feasible
%
% Algorithm: 1-dimensional line-search
%
% Written by Stephen Becker, September 2009, srbecker@caltech.edu
%   for NESTA Version 1.1
% Copied to TFOCS by Stephen Becker, June 2014. stephen.beckr@gmail.com

% -- Parameters for Newton's method --
if nargin < 7, opts = []; end
if isfield(opts,'lambda0'), lambda0 = opts.lambda0; else lambda0 = 0; end
if isfield(opts,'maxit'), MAXIT = opts.maxit; else MAXIT = 70; end
if isfield(opts,'tol'), TOL = opts.tol; else TOL = 1e-8*epsilon; end
if isfield(opts,'disp'), DISP = opts.disp; else DISP = false; end

m = size(U,1);
n = size(V,1);
mn = min([m,n]);
if numel(S) > mn^2, S = diag(diag(S)); end  % S should be a small square matrix
r = size(S);
if size(U,2) > r, U = U(:,1:r); end
if size(V,2) > r, V = V(:,1:r); end

s = diag(S);
s2 = s.^2;

% What we want to do:
%   b = b - A*y;
%   bb = U'*b;

% if A doesn't have full row rank, then b may not be in the range, so
%   treat this specially
if size(U,1) > size(U,2)
    bRange = U*(U'*b);
    bNull = b - bRange;
    epsilon = sqrt( epsilon^2 - norm(bNull)^2 );
end
b = U'*b - S*(V'*y);  % parenthesis is very important!  This is expensive.
    
b2 = abs(b).^2;  % for complex data
bs2 = b2.*s2;
epsilon2 = epsilon^2;

% The following routine need to be fast
% For efficiency (at cost of transparency), we are writing the calculations
% in a way that minimize number of operations.  The functions "f"
% and "fp" represent f and its derivative.

% f = @(lambda) sum( b2 .*(1-lambda*s2).^(-2) ) - epsilon^2;
% fp = @(lambda) 2*sum( bs2 .*(1-lambda*s2).^(-3) );
l = lambda0; oldff = 0;
one = ones(m,1);
alpha = 1;      % take full Newton steps
for k = 1:MAXIT
    % make f(l) and fp(l) as efficient as possible:
    ls = one./(one-l*s2);
    ls2 = ls.^2;
    ls3 = ls2.*ls;
    ff = b2.'*ls2; % should be .', not ', even for complex data
    ff = ff - epsilon2;
    fpl = 2*( bs2.'*ls3 );  % should be .', not ', even for complex data
%     ff = f(l);    % this is a little slower
%     fpl = fp(l);  % this is a little slower
    d = -ff/fpl;
    if DISP, fprintf('%2d, lambda is %5.2f, f(lambda) is %.2e, f''(lambda) is %.2e\n',...
            k,l,ff,fpl ); end
    if abs(ff) < TOL, break; end        % stopping criteria
    l_old = l;
    if k>2 && ( abs(ff) > 10*abs(oldff+100) )
        l = 0; alpha = 1/2; 
        oldff = sum(b2); oldff = oldff - epsilon2;
        if DISP, disp('restarting'); end
    else
        if alpha < 1, alpha = (alpha+1)/2; end
        l = l + alpha*d;
        oldff = ff;
        if l > 0
            l = 0;  % shouldn't be positive
            oldff = sum(b2);  oldff = oldff - epsilon2;
        end
    end
    if l_old == l && l == 0
        if DISP, disp('Making no progress; x = y is probably feasible'); end
        break;
    end
end
if l < 0
    xhat = -l*s.*b./( 1 - l*s2 );
    x = V*xhat + y;
else
    % y is already feasible, so no need to project
    l = 0;
    x = y;
end

end % end of sub-routine



% TFOCS v1.3 by Stephen Becker, Emmanuel Candes, and Michael Grant.
% Copyright 2013 California Institute of Technology and CVX Research.
% See the file LICENSE for full license information.
