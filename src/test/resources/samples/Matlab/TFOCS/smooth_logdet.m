function op = smooth_logdet(q,C)
% SMOOTH_LOGDET   The -log( det( X ) ) function.
%   (Note the minus sign)
%   FUNC = SMOOTH_LOGDET( q ) returns a function handle that
%   provides a TFOCS-compatible implementation of the funciton
%       -q*log( det( X ) )
%
%   FUNC = SMOOTH_LOGDET( q, C ) represents
%       -q*log( det( X ) ) + < C, X >, where C is symmetric/Hermitian
%
%   X must be symmetric/Hermitian and positive definite,
%   and q must be a positive real number (if not provided,
%   the default value is q = 1).
%
%   N.B. it is the user's responsibility to ensure
%   that X is Hermitian and pos. def., since
%   automatically checking is expensive.
%
%   This function is differentiable, but the gradient
%   is not Lipschitz on the domain X > 0
%
%   This function does support proximity operations, and so
%   it may be used as a nonsmooth function.
%   However, the input must be symmetric positive definite
%   (and if C is used, then it must also be > tC )

% SRB: have not yet tested this.
% SRB: I think we CAN compute the proximity operator to logdet.
%       Will implement this in prox_logdet
if nargin < 1, q = 1; end
if nargin < 2, C = []; end
if ~isreal(q) || q <= 0
    error('First argument must be real and positive');
end

%op = @smooth_logdet_impl;
if isempty(C)
    op = @(varargin)smooth_logdet_impl( q, varargin{:} );
else
    op = @(varargin)smooth_logdet_impl_C( q, C, varargin{:} );
end

function [ v, g ] = smooth_logdet_impl( q, x, t )
if size(x,1) ~= size(x,2)
    error('smooth_logdet: input must be a square matrix');
end
switch nargin
    case 2
        % the function is being used in a "smooth" fashion
        %v = -log(det(x));
        v = -2*q*sum(log(diag(chol(x))));  % chol() takes half the time as det()
                                 % and it is easier to avoid overflow errors
                                 % since we sum the logs.
                                 % Also, chol() will warn if not pos. def.
        if nargout > 1
            g = -q*inv(x);
            % it would be nice to make g a function handle
            % that calculates g(y) = -x\y
        end


    case 3
        % the function is being used in a "nonsmooth" fashion
        % i.e. return g = argmin_g  -q*log(det(g)) + 1/(2t)||g-x||^2
        x = full(x+x')/2;  % March 2015, project it to be symmetric
        [V,D]   = safe_eig(x);
        d       = diag(D);
        % This is OK: input need not be pos def
        %if any(d<=0),
            %v   = Inf;
            %g   = nan(size(x));
            %return;
%%             error('log_det requires a positive definite point'); 
        %end
        l       = ( d + sqrt( d.^2 + 4*t*q ) )/2;
        g       = V*diag(l)*V';
        v       = -q*sum(log(l));
    otherwise
        error('Wrong number of arguments');
end


function [ v, g ] = smooth_logdet_impl_C( q, C, x, t )
if size(x,1) ~= size(x,2)
    error('smooth_logdet: input must be a square matrix');
end
if size(C,1) ~= size(C,2)
    error('smooth_logdet: input must be a square matrix');
end
switch nargin
    case 3
        % the function is being used in a "smooth" fashion
        %v = -log(det(x));
        v = -2*q*sum(log(diag(chol(x))));  % chol() takes half the time as det()
                                 % and it is easier to avoid overflow errors
                                 % since we sum the logs.
                                 % Also, chol() will warn if not pos. def.
        v = v + tfocs_dot( C, x );
        if nargout > 1
            g = -q*inv(x) + C;
            % it would be nice to make g a function handle
            % that calculates g(y) = -x\y
        end


    case 4
        % the function is being used in a "nonsmooth" fashion
        % i.e. return g = argmin_g  -q*log(det(g)) + 1/(2t)||g-x||^2
        x       = x - t*C;  
        x = full(x+x')/2;  % March 2015, project it to be symmetric
        [V,D]   = safe_eig(x);
        d       = diag(D);
        % This is OK: input need not be pos def
        l       = ( d + sqrt( d.^2 + 4*t*q ) )/2;
        g       = V*diag(l)*V';
        v       = -q*sum(log(l));
        v       = v + tfocs_dot( C, g );
    otherwise
        error('Wrong number of arguments');
end


% TFOCS v1.3 by Stephen Becker, Emmanuel Candes, and Michael Grant.
% Copyright 2013 California Institute of Technology and CVX Research.
% See the file LICENSE for full license information.
