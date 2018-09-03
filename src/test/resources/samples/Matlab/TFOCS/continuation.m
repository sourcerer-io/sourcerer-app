function [ x, odata, optsOut ] = continuation( fcn, mu, x0, z0, opts, contOpts )
% CONTINUATION Meta-wrapper to run TFOCS_SCD in continuation mode.
% [...] = CONTINUATION( FCN, MU, X0, Z0, OPTS, CONT_OPTS )
%   is a wrapper to perform continuation on FCN, where
%   FCN is a function that calls tfocs_SCD or a tfocs solver.
%   FCN must accept input arguments MU, X0, Z0, and OPTS,
%       e.g. FCN = @(mu,x0,z0,opts) solver_sBP( A, b, mu, x0, z0, opts )
%
%   CONT_OPTS are options that affect how continuation is performed.
%   To see the default options, call this script with no inputs.
%
%   Options for CONT_OPTS:
%       maxIts      - max # of continuation iterations
%       accel       - use accelerated continuation or not
%       betaTol     - every continuation iteration, the tolerance
%                       is decreased by 'betaTol'
%       innerTol    - every continuation iteration, except the last one,
%                       is solved to this tolerance.
%                       This option overrides 'betaTol'
%       tol         - the outer loop will stop when either
%                       'maxIts' is reached, or when the change
%                       from one step to the next is less than 'tol'.
%                     If innerTol is not specified, then "tol" and "betaTol"
%                       are used to determine the tolerance of intermediate solves.
%       initialTol  - For use with "tol". This overrides betaTol, but in turn is
%                       overridden by innerTol.  If specified, then the first
%                       problem is solved to tolerance "initialTol" and the final
%                       problem is solved to tolerance "tol", and all problems
%                       in between are solved to logarithmically interpolated values.
%                       E.g. if maxits = 3 and initialTol = .1 and tol = .001,
%                         then the tolerances are .1, .01, .001.
%       finalTol    - For use with "tol".  If "finalTol" is set, then "tol"
%                       and "betaTol" are used to determine the tolerance of
%                       intermediate solves, but the last solve is solved
%                       to the "finalTol" tolerance.
%       innerMaxIts - maximum number of inner iterations during
%                       every continuation iteration except the last one.
%       muDecrement - after every iteration, mu <-- mu*muDecrement
%                       (default: muDecrement = 1, so mu is constant)
%       verbose     - true  (default) prints out information, false will
%                        not print out any information
%
% As of release 1.1, you do not need to call this file directly. Instead,
% you can specify the continuation option in TFOCS_SCD.m directly.
% See also TFOCS_SCD.m

if nargin < 6, contOpts = []; end
kMax    = setOpts('maxIts',3);
ACCEL   = setOpts('accel',true);
betaTol = setOpts('betaTol',2);
innerTol= setOpts('innerTol',[] );
stopTol = setOpts('tol',1e-3);
finalTol= setOpts('finalTol',[]);
verbose = setOpts('verbose',true);
innerMaxIts = setOpts('innerMaxIts',[] );
initialTol  = setOpts('initialTol',[]);
muDecrement = setOpts('muDecrement',1);
finalRestart = setOpts('finalRestart',[]); % not yet documented. usefulness?

if nargin == 0
    if nargout == 0
        disp('Default options for CONTINUATION are:');
    end
    x = contOpts;
    return;
end

error(nargchk(2,6,nargin));
if nargin < 3, x0   = []; end
if nargin < 4, z0   = []; end
if nargin < 5, opts = []; end

% what is the user specified stopping tolerance?
if ~isfield(opts,'tol')
    % get the default value:
    defaultOpts = tfocs_SCD();
    opts.tol = defaultOpts.tol;
end
if isfield(opts,'fid'), fid = opts.fid; else fid = 1; end


finalTol2    = opts.tol;
if isempty( innerTol ) && ~isempty(initialTol)
    % calculate the value of betaTol that will
    betaTol     = exp( log(initialTol/finalTol2)/(kMax-1) );
end
% tol         = finalTol2*betaTol^(kMax+1); % bug fixed Feb 2011
tol         = finalTol2*betaTol^(kMax);

L0   = Inf; % for first round, use default value of stepsize
xOld = x0;
odataCumulative      = [];
odataCumulative.niter= 0;
extraVerbose = verbose && (isfield(opts,'printEvery') && (opts.printEvery <= 0 ...
    || opts.printEvery == Inf ) );
for k = 1:kMax
    if kMax > 1 && verbose
%         fprintf(fid,'--- Continuation step %d of %d ', k, kMax );
        fprintf(fid,'--- Continuation step %d of %d, mu: %.1e', k, kMax, mu );
        if extraVerbose
            fprintf(fid,' ...');
        else
            fprintf('\n');
        end
    end
    
    optsTemp    = opts;
    if ~isempty( innerMaxIts ) && k < kMax
        optsTemp.maxIts     = innerMaxIts;
    end
    tol             = tol/betaTol;
    if ~isempty( innerTol ) && k < kMax
        optsTemp.tol    = innerTol;
    else
        if ~isempty(finalTol) && k == kMax 
            optsTemp.tol = finalTol;
        else
            optsTemp.tol    = tol;
        end
    end
    if k == kMax && ~isempty( finalRestart )
        optsTemp.restart    = finalRestart; 
    end
    if isfinite(L0)
        optsTemp.L0     = L0;
    end
    
    % call the solver
    [x, odata, optsOut ] = fcn( mu, x0, z0, optsTemp );
    
    if iscell(x)
        % Thanks to Graham Coleman for catching this case
        if isempty(x0)
            mu2normXX   =   mu/2*sum(cellfun( @(x) norm(x(:))^2, x ));
        elseif iscell(x0)
            mu2normXX   =   mu/2*sum(cellfun( @(x) norm(x(:))^2, ...
                cellfun( @minus, x, x0,'uniformoutput',false ) ));
        else
            mu2normXX   =   mu/2*sum(cellfun( @(x) norm(x(:))^2, ...
                cellfun( @(x) x-x0, x, 'uniformoutput',false ) ));
        end
    else
        if isempty(x0)
            mu2normXX   = mu/2*norm(x(:))^2;
        else
            mu2normXX   = mu/2*norm(x(:)-x0(:))^2;
        end
    end
    
    % (possibly) decrease mu for next solve
    mu = mu*muDecrement;
    
    % Dec '13, use stepsize estimate
    L0  = 1/odata.stepsize(end);
    
    % update output data
    fields = { 'f', 'normGrad', 'stepsize','theta','counts','err' };
    for ff = fields
        f = ff{1};
        if isfield(odata,f) 
            if isfield(odataCumulative,f)
                odata.(f) = [odataCumulative.(f); odata.(f)];
            end
            odataCumulative.(f) = odata.(f);
        end
        
    end
    if isfield(odata,'niter')
        % include the old iterations in the count
        odataCumulative.niter = odata.niter + odataCumulative.niter;
        odata.niter     = odataCumulative.niter;
        
        % record at which iterations continuation happened
        if isfield(odataCumulative,'contLocations')
            odataCumulative.contLocations = [odataCumulative.contLocations; odata.niter];
            odata.contLocations = odataCumulative.contLocations;
        else
            odata.contLocations = odata.niter;
            odataCumulative.contLocations = odata.niter;
        end
    end
    
    if kMax > 1 && extraVerbose
        fprintf(fid,'\b\b\b\b'); % remove the " ..." from earlier
    end
    % if the tfocs solver is set to be quiet, but the continuation
    % script still has the "verbose" flag, then print out
    %   some information
    if extraVerbose && isfield( odata, 'err' ) && ~isempty( odata.err )
        fprintf(fid,', errors: ');
        fprintf(fid,' %8.2e', odata.err(end,:) );
    end
    if verbose
        if extraVerbose
            fprintf(fid,', mu/2||x-x_0||^2: %.1e', mu2normXX );
        else
            fprintf(fid,'Continuation statistics: mu/2||x-x_0||^2: %.1e', mu2normXX );
        end
        
        if kMax > 1 && extraVerbose
            fprintf(fid,' ---');
        end
        fprintf(fid,'\n');
    end
    
    
    if k == kMax, break; end
    
    % Update the prox center
    
    if ACCEL
        if iscell(x)
            if isempty(xOld) || ~iscell(xOld)
                 xOld = cell( size(x) ); 
            end
            x0 = cell( size(x) );
            for nCell = 1:length(x)
                if isempty(xOld{nCell}), xOld{nCell} = zeros( size(x{nCell}) ); end
                x0{nCell} = x{nCell} + (k-1)/(k+2)*( x{nCell} - xOld{nCell} );
            end
            
        else
            if isempty(xOld), xOld = zeros(size(x)); end
            x0 = x + (k-1)/(k+2)*( x - xOld );
        end
    else
        x0 = x;
    end
    
    if isa( odata.dual, 'tfocs_tuple')
        z0 = cell( odata.dual );
    else
        z0 = odata.dual;
    end
    
    
    if iscell(x)
        n1=sqrt(sum(cellfun( @(x) norm(x(:))^2, cellfun( @minus, x, xOld,'uniformoutput',false ) )));
        n2=sqrt(sum(cellfun( @(x) norm(x(:))^2, xOld )));
    else
        n1 = norm(x(:)-xOld(:));
        n2 = norm(xOld(:));
    end

    if n1/n2 <= stopTol && verbose
        fprintf(fid,'Continuation ending, due to convergence\n');
        break;
    end
    xOld = x;
    if k == kMax && verbose
        fprintf(fid,'Continuation ending, due to reaching maximum number of outer iterations\n');
    end
end


function out = setOpts(fieldName,default)
    if ~isfield(contOpts,fieldName)
        contOpts.(fieldName) = default;
    end
    out = contOpts.(fieldName);
end


end

% TFOCS v1.3 by Stephen Becker, Emmanuel Candes, and Michael Grant.
% Copyright 2013 California Institute of Technology and CVX Research.
% See the file LICENSE for full license information.
