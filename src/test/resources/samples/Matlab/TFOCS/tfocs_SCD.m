function [ x, odata, opts ] = tfocs_SCD( objectiveF, affineF, dualproxF, mu, x0, z0, opts, contOpts )
% TFOCS_SCD Smoothed conic dual form of TFOCS, for problems with non-trivial linear operators.
% [ x, out, opts ] = tfocs_SCD( objectiveF, affineF, dualproxF, mu, x0, z0, opts )
%   Solves a conic problem using the smoothed conic dual approach. The goal
%   is to solve a problem in the following conic form:
%       minimize objectiveF(x)+0.5*mu(x-x0).^2
%       s.t.     affineF(x) \in \cK
%   The user is responsible for constructing the dual proximity function
%   so that the dual can be described by the saddle point problem
%        maximize_z inf_x [ objectiveF(x)+0.5*mu(x-x0).^2-<affineF(x),z> ] -dualproxF(z)
%   If mu = Inf, the method ignores the objective function and solves
%       minimize 0.5*(x-x0).^2
%       s.t.     affineF(x) \in \cK
%
%   dualProxF is also known as conjnegF
%       It is the Fenchel-Legendre dual up to a -1 scaling of the argument
%
%   For general usage instructions, see tfocs.m and the user guide.
%   In general, setting a variable to [] will set it to its default value.
%
%   If opts.continuation is true, then
% [ x, out, opts ] = tfocs_SCD( objectiveF, affineF, dualproxF, mu, x0, z0, opts )
%   or
% [ x, out, opts ] = tfocs_SCD( objectiveF, affineF, dualproxF, mu, x0, z0, opts, continuationOptions )
%   will update x0 as to eliminate the influence of the mu(x-x0).^2 term
%   Parameters for the continuation scheme are optionally specified
%   in the "continuationOpts" variable.
%   Note: if the "continuationOpts" variable is given, then the solver
%     enters continuation mode automatically, unless opts.continuation
%     is explicitly set to false.
%   To see options available for continuation, type "continuation()"
%
%   See also tfocs

if nargin == 0
    % pass in the SCD specific options:
    opSCD   = [];
    opSCD.continuation  = false;
    opSCD.adjoint       = true;
    opSCD.saddle        = true;
    opSCD.maxmin        = -1;
    if nargout > 0, x = tfocs(opSCD);
        % and set the continuation options (right now, continuation is off by default)
         x.continuation  = false;
         x = rmfield(x,'adjoint'); % x.adjoint       = true;
         x.saddle        = true;
         x.maxmin        = -1;
    else
        tfocs(opSCD);
        disp('Warning: we strongly recommend setting opts.continuation=true; see the user guide');
        disp('Type ''help continuation'' for details');
    end
    return;
end

error(nargchk(4,8,nargin));
if nargin < 5, x0 = []; end
if nargin < 6, z0 = []; end
if nargin < 7, opts = []; end

% look for continuation options
DO_CONTINUATION     = false;
if nargin >= 8
    DO_CONTINUATION = true; 
else
    contOpts        = [];
end
if isfield( opts, 'continuation' )
    if opts.continuation
        DO_CONTINUATION     = true;
    else
        DO_CONTINUATION     = false;
    end
    opts    = rmfield(opts,'continuation');
end

% Handle special cases of zero objective or infinite mu
if isinf( mu ),
    mu = 1;
    objectiveF = prox_0;
elseif isempty( objectiveF ),
    objectiveF = prox_0;
elseif iscell( objectiveF )  % allow the case of {[],[],...,[]}
    for k = 1:length(objectiveF)
        if isempty( objectiveF{k} ) || isequal( objectiveF{k}, 0 ),
            objectiveF{k} = prox_0;
        elseif isnumeric( objectiveF{k} ),
            objectiveF{k} = smooth_linear( objectiveF{k} );
        end
    end
end

% The affine quantities will be used in adjoint orientation
if isfield( opts, 'adjoint'  ),
    opts.adjoint = ~opts.adjoint;
else
    opts.adjoint = true;
end
opts.saddle = true;
opts.maxmin = -1;
if isempty( x0 ), x0 = 0; end
smoothF = create_smoothF( objectiveF, mu, x0 );

if isempty(dualproxF)
    dualproxF = proj_Rn;
elseif iscell(dualproxF)
    for k = 1:length(dualproxF)
        dp = dualproxF{k};
        if isempty( dp ) || isnumeric( dp ) && numel( dp ) == 1 && dp == 0,
            dualproxF{k} = proj_Rn;
        end
    end
end
% When tfocs.m finds an error with z0, it says it has an error with "x0",
%   which is confusing for tfocs_SCD users, since their "x0" has a different meaning.
% try  % this is annoying for debugging
    if DO_CONTINUATION
        continuation_solver=@(mu,x0,z0,opts)solver(objectiveF,affineF,dualproxF, mu,x0,z0,opts);
        [ x, odata, opts ] = continuation( continuation_solver, mu, x0, z0, opts,contOpts );
    else
        [ z, odata, opts ] = tfocs( smoothF, affineF, dualproxF, z0, opts );
    end
% catch err
%     if strfind( err.message, 'x0' )
%         fprintf(2,'Error involves z0 (which is referred to as x0 below)\n');
%     end
%     rethrow(err);
% end
opts.adjoint = ~opts.adjoint;
opts = rmfield( opts, { 'saddle', 'maxmin' } );
if DO_CONTINUATION
    opts.continuation   = true;
else
    x = odata.dual;
    odata.dual = z;
end



% ----------------------- Subfunctions ----------------------------------------

function [ prox, x ] = smooth_dual( objectiveF, mu_i, x0, ATz )
% Adding 0 to ATz will destroy the sparsity
if (isscalar(x0) && x0 == 0) || numel(x0) == 0 || nnz(x0) == 0
    [ v, x ] = objectiveF( mu_i * ATz, mu_i );
else
    [ v, x ] = objectiveF( x0 + mu_i * ATz, mu_i );
end
prox = tfocs_dot( ATz, x ) - v - (0.5/mu_i) * tfocs_normsq( x - x0 );
prox = -prox;
x = -x;

function [ prox, x ] = smooth_dual_vectorMu( objectiveF, mu_i, x0, ATz )
% Adding 0 to ATz will destroy the sparsity
if (isscalar(x0) && x0 == 0) || numel(x0) == 0 || nnz(x0) == 0
    [ v, x ] = objectiveF( mu_i .* ATz, mu_i );
else
    [ v, x ] = objectiveF( x0 + mu_i .* ATz, mu_i ); % Causes a scaling...
end
prox = tfocs_dot( ATz, x ) - v - 0.5*tfocs_normsq( x - x0, 1./mu_i );
prox = -prox;
x = -x;


function smoothF = create_smoothF( objectiveF, mu, x0 )
if iscell(objectiveF)
    for k = 1 : length(objectiveF)
        if iscell(x0)
            if length(mu)>1
              smoothF{k} = @(varargin)smooth_dual_vectorMu( objectiveF{k}, 1./mu, x0{k}, varargin{:} );
            else
              smoothF{k} = @(varargin)smooth_dual( objectiveF{k}, 1./mu, x0{k}, varargin{:} );
            end
        else
            if length(mu)>1
              smoothF{k} = @(varargin)smooth_dual_vectorMu( objectiveF{k}, 1./mu, x0, varargin{:} );
            else
              smoothF{k} = @(varargin)smooth_dual( objectiveF{k}, 1./mu, x0, varargin{:} );
            end
        end
    end
else
    if length(mu)>1
      smoothF = @(varargin)smooth_dual_vectorMu( objectiveF, 1./mu, x0, varargin{:} );
    else
      smoothF = @(varargin)smooth_dual( objectiveF, 1./mu, x0, varargin{:} );
    end
end

% For use with continuation:
function [varargout] = solver(objectiveF,affineF,dualproxF, mu,x0,z0,opts)
smoothF = create_smoothF( objectiveF, mu, x0 );
[varargout{1:max(nargout,2)}] = tfocs( smoothF, affineF, dualproxF, z0, opts );
% The varargout should be [x, odata, opts ]
% Since we're using the dual, need to switch
dualVar = varargout{1};
odata   = varargout{2};
varargout{1} = odata.dual;
odata.dual   = dualVar;
varargout{2} = odata;




% TFOCS v1.3 by Stephen Becker, Emmanuel Candes, and Michael Grant.
% Copyright 2013 California Institute of Technology and CVX Research.
% See the file LICENSE for full license information.
