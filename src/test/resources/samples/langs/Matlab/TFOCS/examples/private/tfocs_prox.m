function op = tfocs_prox( f, prox_f, VECTOR_SCALAR )
% OP = TFOCS_PROX( F, PROX_F )
%   combines F and PROX_F into the appropriate TFOCS-compatible object.
%
%   F is any function (with known proximity operator),
%   and PROX_F is its proximity operator, defined as:
%
%   PROX_F( Y, t ) = argmin_X  F(X) + 1/(2*t)*|| X - Y ||^2
%
%   To use this, please see the file PROX_L1 as an example
%
%   The basic layout of a file like PROX_L1 is as follows:
%   ( for the function F(X) = q*||X||_1 )
%
%       function op = prox_l1(q)
%       op = tfocs_prox( @f, @prox_f )
%
%         function v = f(x)
%           ... this function calculates the function f ...
%         end
%         function v = prox_f(y,t)
%           ... this function calculates the prox-function to f ...
%         end
%       end
%
%   Note: in the above template, the "end" statements are very important.
%
% OP = TFOCS_PROX( F, PROX_F, 'vector')
%   will signal the routine that it is OK to allow "vector" stepsizes
%   (this corresponds to solving
%       PROX_F( Y, T ) = argmin_X F(X) + 1/2( X-Y )'*diag(1./T)*( X-Y )
%    where T is a vector of the same size as X ).
% ... = TFOCS_PROX( F, PROX_F, 'scalar' )
%   will throw an error if a vector stepsize is attempted. This is the default.
%
%   Also, users may wish to test their smooth function
%   with the script TEST_NONSMOOTH
%
%   See also prox_l1, test_nonsmooth

if nargin < 3 || isempty(VECTOR_SCALAR)
    VECTOR_SCALAR = 'scalar';
end

if strcmpi(VECTOR_SCALAR,'scalar')
%     op = @fcn_impl; % comment this out and use octave-compatible version below:
%     op = @(x,t)fcn_impl(f,prox_f,x,t); % this doesn't work: requires 2 inputs always
    op = @(varargin)fcn_impl(f,prox_f,varargin{:});
elseif strcmpi(VECTOR_SCALAR,'vector')
%     op = @fcn_impl_vector; % comment this out and use octave-compatible version below:
%     op = @(x,t)fcn_impl_vector(f,prox_f,x,t); % this doesn't work: requires 2 inputs always
    op = @(varargin)fcn_impl_vector(f,prox_f,varargin{:});
else
    error('bad option for VECTOR_SCALAR parameter');
end

function [ v, x ] = fcn_impl(f,prox_f,x, t )
    if nargin < 3,
        error( 'Not enough arguments.' );
    end
    if nargin == 4,
        if numel(t) ~= 1, error('The stepsize must be a scalar'); end
        x  = prox_f(x,t);
    elseif nargout == 2,
        error( 'This function is not differentiable.' );
    end
    v = f(x);
end

function [ v, x ] = fcn_impl_vector(f,prox_f,x, t )
    if nargin < 3,
        error( 'Not enough arguments.' );
    end
    if nargin == 4,
        x  = prox_f(x,t);
    elseif nargout == 2,
        error( 'This function is not differentiable.' );
    end
    v = f(x);
end

% - Octave incompatible version: -
% function [ v, x ] = fcn_impl(x, t )
%     if nargin < 1,
%         error( 'Not enough arguments.' );
%     end
%     if nargin == 2,
%         if numel(t) ~= 1, error('The stepsize must be a scalar'); end
%         x  = prox_f(x,t);
%     elseif nargout == 2,
%         error( 'This function is not differentiable.' );
%     end
%     v = f(x);
% end
% 
% function [ v, x ] = fcn_impl_vector(x, t )
%     if nargin < 1,
%         error( 'Not enough arguments.' );
%     end
%     if nargin == 2,
%         x  = prox_f(x,t);
%     elseif nargout == 2,
%         error( 'This function is not differentiable.' );
%     end
%     v = f(x);
% end


end

% TFOCS v1.3 by Stephen Becker, Emmanuel Candes, and Michael Grant.
% Copyright 2013 California Institute of Technology and CVX Research.
% See the file LICENSE for full license information.