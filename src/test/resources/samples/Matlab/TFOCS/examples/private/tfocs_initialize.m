%SOLVER_INITIALIZE	TFOCS helper script
%	Performs the initializations common to all of the first-order solvers

% Process the options structure and string/value pairs. First, we replace the
% default values with any values specified by the user in the 'opts' structure.
% We ignore any fields in the 'opts' structure that do not match ours, so that
% users can re-use the opts structure for other purposes.

odef = struct( ...
    'maxIts',     Inf   ,...
    'maxCounts',  Inf   ,...
    'countOps',   false ,... % adjusted if maxCounts < Inf
    'saveHist',   true  ,...
    'adjoint',    false ,...
    'saddle',     false ,...
    'tol',        1e-8  ,...
    'errFcn',     {{}}  ,...
    'stopFcn',    {{}}  ,...
    'printEvery', 100   ,...
    'maxmin',     1     ,...
    'beta',       0.5   ,...
    'alpha',      0.9   ,... % See below for special CG stuff
    'L0',         1     ,... % See below 
    'Lexact',     Inf   ,...
    'mu',         0     ,...
    'fid',        1     ,...
    'stopCrit',   1     ,... % the TFOCS paper used stopCrit = 2
    'alg',        'AT'  ,...
    'restart',    Inf   ,...
    'printStopCrit', false,...
    'cntr_reset',  -50   ,... % how often to explicitly recompute A*x and A*y (set to Inf if you want )
    'cg_restart', Inf   ,... % for CG only
    'cg_type',    'pr'  ,...  % for CG only
    'stopping_criteria_always_use_x',   false, ...
    'data_collection_always_use_x',     false, ...
    'output_always_use_x',              false,  ...
    'autoRestart',  'gra', ... % function or gradient
    'printRestart', true, ...
    'debug',      false ....
    );

% Calling the solver with a no arguments returns the default options structure
if narginn < 1 || ( narginn ==1 && isstruct( smoothF ) )
    opts = odef;
    % remove the "CG" options for now, since they are undocumented
    opts    = rmfield(opts,'cg_restart');
    opts    = rmfield(opts,'cg_type');
    % if any default options are passed in (e.g. by tfocs_SCD), add those now:
    if ( narginn ==1 && isstruct( smoothF ) )
        for f = fieldnames( smoothF )'
            opts.( f{1} )   = smoothF.( f{1} );
        end
    end
    
    out = [];
    x = opts;
    if nargoutt == 0,
        disp('====== TFOCS default options =======');
%         disp('Format is    fieldname: { [default]  ''Usage type.
%         Description''}');
        
        % add some helpful description
        desc = [];
        desc.alg    = 'Algorithm, e.g. GRA for gradient descent. Values: AT, GRA, LLM, N07, N83, TS';
        desc.maxIts = 'Basic. Maximum number of allowed iterations';
        desc.saveHist   = 'Basic. Record history of all iterations';
        desc.restart    = 'Basic. Restart parameter. Make negative for "no-regress" feature';
        desc.tol    = 'Basic. Tolerance for stopping criteria';
        desc.L0     = 'Basic. Initial estimate of Lipschitz constant';
        desc.Lexact = 'Basic. Known bound of Lipschitz constant';
        desc.printEvery = 'Basic. How often to print info to the terminal; set to 0 or Inf to suppress output';
        desc.maxmin = 'Basic. +1 for convex minimization, -1 for concave maximization';
        
        desc.errFcn = 'Medium. User-specified error function. See user guide';
        desc.beta   = 'Medium. Backtracking parameter, in (0,1). No line search if >= 1';
        desc.alpha  = 'Medium. Line search increase parameter, in (0,1)';
        desc.autoRestart= 'Medium. Set to ''gra'' or ''fun'' to choose behavior when restart<0';

        
        desc.maxCounts  = 'Advanced. Vector that fine-tunes various types of iteration limits; same form as countOps';
        desc.countOps   = 'Advanced. Record number of linear multiplies, etc.; form [fcn, grad, linear, nonsmth, proj]';
        desc.mu         = 'Advanced. Strong convexity parameter.';
        desc.fid        = 'Advanced. File id, e.g. via fopen. All output is sent to this file';
        desc.stopFcn    = 'Advanced. User-supplied stopping criteria. See user guide';
        desc.stopCrit   = 'Advanced. Controls which stopping criteria to use; 1,2, 3 or 4.';
        desc.printStopCrit = 'Advanced. Controls whether to display the value used in the stopping criteria';
        desc.printRestart  = 'Advanced. Whether to signal when a restart happens';
        desc.cntr_reset = 'Advanced. Controls how often to reset some numerical computations to avoid roundoff';
        desc.debug = 'Advanced.  Turns on more useful error messages';
        
        desc.stopping_criteria_always_use_x = 'Advanced. Forces usage of x, never y, in stopping crit.';
        desc.data_collection_always_use_x   = 'Advanced. Forces usage of x, nevery y, in recording errors.';
        desc.output_always_use_x            = 'Advanced. Forces output of x, never y. Default: uses whichever is better';
        
        desc.adjoint = 'Internal.';
        desc.saddle = 'Internal.  Used by TFOCS_SCD';
        
        
        
        disp( opts );
        disp('====== Description of TFOCS options =======');
        disp( desc );
    end
    return % from this script only; the calling function does not return
end

% [smoothF, affineF, projectorF, x0, opts ] = deal(varargin{:});
% Check for incorrect types
F_types = {'function_handle','cell','double','single'};
assert( ismember(class(smoothF),F_types),'smoothF is of wrong type' );
assert( ismember(class(affineF),F_types),'affineF is of wrong type' );
assert( ismember(class(projectorF),F_types),'projectorF 3 is of wrong type' );
if narginn >= 4
    x0_types = {'cell','double','single','tfocs_tuple'};
    assert( ismember(class(x0),x0_types),'x0 is of wrong type' );
end
if narginn >= 5 && ~isempty(opts)
    assert( ismember(class(opts),{'struct'}),'opts is of wrong type' );
end

% Some parameters defaults depend on whether the user supplies other
% options. These will be updated later
L0_default  = odef.L0;
odef.L0     = Inf;

alpha_default    = odef.alpha; % typically 0.9
alpha_default_CG = 1;
odef.alpha  = Inf;



% Process the options structure, merging it with the default options
%   (merge "opts" into "odef")
def_fields = fieldnames(odef)';              % default options
if narginn > 4 && ~isempty(opts),
    use_fields = zeros(size(def_fields));
    opt_fields = fieldnames(opts)';          % user-supplied options
    for k = opt_fields,
        k = k{1};
        ndx = find(strcmpi(def_fields,k));
        if ~isempty(ndx)
            if ~isempty(opts.(k)) && ~use_fields(ndx),
                odef.(def_fields{ndx}) = opts.(k);
            end
            use_fields(ndx) = use_fields(ndx) + 1;
        else
            % Warn if the field is not found in our options structure
            warnState = warning('query','backtrace');
            warning off backtrace
            warning('TFOCS:OptionsStructure',' Found extraneous field "%s" in options structure', k );
            warning(warnState);
        end
    end
    % Warn if fields appear twice due to capitalization; e.g., maxIts/maxits
    if any(use_fields>1),
        warnState = warning('query','backtrace');
        warning off backtrace
        warning('TFOCS:OptionsStructure',' Some fieldnames of the options structure are identical up to capitalization: unpredictable behavior');
        warning(warnState);
    end
end

% Remove unnecessary options
if ~strcmpi( odef.alg, 'cg' )
    odef = rmfield( odef, 'cg_restart' );
    odef = rmfield( odef, 'cg_type' );
    % update our list of fieldnames
    def_fields = fieldnames(odef)';
end

% If opts.alpha wasn't supplied, use a default value:
if isinf(odef.alpha)
    if strcmpi( odef.alg, 'cg' )
        odef.alpha = alpha_default_CG;
    else
        odef.alpha = alpha_default;
    end
end

% If opts.printEvery is Inf, set it to 0
if isinf(odef.printEvery)
    odef.printEvery = 0;
end

% The default value of L0 is set to Lexact, if it is supplied
if isinf(odef.L0),
    if isinf(odef.Lexact),
        if odef.beta >= 1,
            error( 'For a fixed step size, L0 or Lexact must be supplied.' );
        end
        odef.L0 = L0_default;
    else
        odef.L0 = odef.Lexact;
    end
end
% If maxCounts is set, set countOps to true
if any(odef.maxCounts<Inf),
    odef.countOps = true;
end
% If cntr_reset is not set (signfied by being negative), set to defaults
if odef.cntr_reset < 0
    odef.cntr_reset = round(abs(odef.cntr_reset));
    % and if we requested high precision, change the default
    if odef.tol < 1e-12
        odef.cntr_reset = 10; 
    end
end

% Now move the options into the current workspace
for k = def_fields,
    assignin('caller',k{1},odef.(k{1}));
end
opts = odef;

%
% Smooth function, pass 1
%

if isempty( smoothF ),
	error( 'Must supply a smooth function specification.' );
elseif isa( smoothF, 'function_handle' ),
    smoothF = { smoothF };
elseif ~isa( smoothF, 'cell' ),
    error( 'smoothF must be a function handle, or a cell array of them.' );
end
n_smooth = numel(smoothF);
saddle_ndxs = 1 : n_smooth;
% Adding Feb 2011: a get_dual function (see below)


%
% Projector, pass 1
%

if isa( projectorF, 'function_handle' ),
    projectorF = { projectorF };
elseif ~isa( projectorF, 'cell' ) && ~isempty( projectorF ),
    error( 'projectorF must be a function handle, or a cell array of them.' );
end
n_proj = numel(projectorF);

%
% Linear functions and affine offsets
%

% If the affine operator is anything *but* a cell array, convert it to one.
maxmin = sign(maxmin);
if isempty( affineF )
    affineF = { @linop_identity };
elseif isnumeric( affineF ),
    if ndims(affineF) > 1,
        error( 'Multidimensional arrays are not permitted.' );
    end
    if numel(affineF) == 1,
        identity_linop = affineF == 1;
        affineF = { linop_scale( affineF ) };
    else
        identity_linop = false;
        affineF = { linop_matrix( affineF ) };
    end
elseif isa( affineF, 'function_handle' ),
    affineF = { affineF };
elseif ~isa( affineF, 'cell' ),
    error( 'Invalid affine operator specification.' );
end

% If adjoint mode is specified, temporarily transpose the affineF cell
% array so that the rows and columns match the number of smooth functions
% and projectors, respectively. Then verify size compatibility.
if adjoint, affineF = affineF'; end
[ m_aff, n_aff ] = size( affineF );
% if all( m_aff ~= n_smooth + [0,1] ) || n_proj && all( n_aff ~= n_proj + [0,1] ),
%     error( 'The affine operation matrix has incompatible dimensions.' );
% May 16, 2011: making error messages more informative
if all( m_aff ~= n_smooth + [0,1] )
    if fid
        fprintf(fid,'Detected error: inputs are of wrong size\n');
        fprintf(fid,'  Found %d smooth functions, so expect that many primal variables\n',...
            n_smooth );
        fprintf(fid,'  So the affine operator should have %d (or %d if there is an offset) entries\n',...
            n_smooth, n_smooth+1 );
        fprintf(fid,'  but instead found %d affine operators\n', m_aff );
        fprintf(fid,' Perhaps you need the transpose of the affine operator?\n');
    end
    error( 'The affine operation matrix has incompatible dimensions.' );
elseif n_proj && all( n_aff ~= n_proj + [0,1] ),
    if fid
        fprintf(fid,'Detected error: inputs are of wrong size\n');
        fprintf(fid,'  Found %d nonsmooth functions, so expect %d or %d sets of affine operators\n',...
            n_proj, n_proj, n_proj + 1 );
        fprintf(fid,'  but instead found %d affine operators\n', n_aff );
    end
    error( 'The affine operation matrix has incompatible dimensions.' );
elseif n_proj == 0,
    n_proj = max( 1, m_aff - 1 );
end
inp_dims = cell( 1, n_proj );
otp_dims = cell( 1, n_smooth );

% If an additional affine portion of the objective has been specified,
% create an additional smooth function to contain it.
if m_aff == n_smooth + 1,
    offset          = true; % note: saddle_ndxs is 1:n_smooth
    otp_dims{end+1} = [1,1];
    smoothF{end+1}  = smooth_linear( maxmin );
    n_smooth = n_smooth + 1;
    for k = 1 : n_proj,
        offX = affineF{end,k};
        if isempty(offX),
            affineF{end,k} = 0;
        elseif isa(offX,'function_handle'),
            if adjoint, pos = 'row'; else pos = 'column'; end
            error( 'The elements in the last %s must be constants.', pos );
        elseif isnumeric(offX) && numel(offX) == 1 && offX == 0,
            affineF{end,k} = 0;
        elseif nnz(offX),
            affineF{end,k} = linop_dot( affineF{end,k}, adjoint );
            % add a case if ~nnz(offX)... Jan 2012
        elseif ~nnz(offX)
            affineF{end,k} = 0;
        end
    end
else
    offset      = false;
end

% If an affine offset has been specified, integrate those offsets into
% each smooth function, then remove that portion of the array.
if n_aff == n_proj + 1,
    for k = 1 : n_smooth,
        offX = affineF{k,end};
        if isempty(offX),
            continue;
        elseif isa(offX,'function_handle'),
            if adjoint, pos = 'column'; else pos = 'row'; end
            error( 'The elements in the last %s must be constant matrices.', pos );
        elseif isnumeric(offX) && numel(offX) == 1 && offX == 0,
            continue;
        else
            otp_dims{k} = size(offX);
            if nnz(offX),
                smoothF{k} = @(x)smoothF{k}( x + offX );
            end
        end
    end
    n_aff = n_aff - 1;
    affineF(:,end) = [];
end


% -- Todo:
%   If opts.debug = true, then before calling linop_stack,
%   we should print a message showing the sizes of everything
%   (this is useful when the linear portion is entered as "1" or "[]"
%    and we have automatically determined the size ).

% Transpose back, if necessary; then check dimensions
if adjoint,
    affineF = affineF';
    [ linearF, otp_dims, inp_dims ] = linop_stack( affineF, otp_dims, inp_dims, debug );
    linearF = linop_adjoint( linearF );
else
    [ linearF, inp_dims, otp_dims ] = linop_stack( affineF, [], [], debug );
end
identity_linop = isequal( linearF, @linop_identity ); % doesn't always catch identities
square_linop = identity_linop || isequal( inp_dims, otp_dims );
adj_arr = [0,2,1];
if countOps,
    apply_linear = @(x,mode)solver_apply( 3, linearF, x, mode );
else
    apply_linear = linearF;
end

%
% Smooth function, pass 2: integrate scale, counting
%

smoothF = smooth_stack( smoothF );
if maxmin < 0,
    smoothF = tfunc_scale( smoothF, -1 );
end
if countOps,
    apply_smooth = @(x)solver_apply( 1:(1+(nargoutt>1)), smoothF, x );
else
    apply_smooth = smoothF;
end

%
% Projector, pass 2: supply default, stack it up, etc.
%

if isempty( projectorF ),
    n_proj = 0;
    projectorF = proj_Rn;
else
    projectorF = prox_stack( projectorF );
end
if countOps,
    apply_projector = @(varargin)solver_apply( 4:(4+(nargoutt>1)), projectorF, varargin{:} );
else
    apply_projector = projectorF;
end

%
% Initialize the op counts
%

if countOps,
    global tfocs_count___
    tfocs_count___ = [0,0,0,0,0];
    maxCounts = maxCounts(:)';
end

%
% Construct the common initial values
%

L = L0;
theta = Inf;
f_v_old = Inf;
x = []; A_x = []; f_x = Inf; C_x = Inf; g_x = []; g_Ax = [];
restart_iter = 0;
warning_lipschitz = 0;
backtrack_simple = true;
backtrack_tol = 1e-10;
backtrack_steps = 0;

%
% Try to determine the size of the input, and construct the initial point.
%

% Attempt 1: From x0 itself
zero_x0 = true;
if ~isempty( x0 ),
    if isa( x0, 'tfocs_tuple' )
        x0  = cell(x0);
    end
    if isa( x0, 'cell' ),
        n_x0 = numel( x0 );
        if n_x0 == 1,
            x0 = x0{1};
        else
            x0 = tfocs_tuple( x0 );
        end
    else
        n_x0 = 1;
    end
    if n_proj && n_proj ~= n_x0,
        error( 'Size conflict detected between the projector and x0.' );
    end
    zero_x0 = ~nnz(x0);
% Attempt 2: From the linear operator dimensions
elseif ~size_ambig( inp_dims ),
    x0 = tfocs_zeros( inp_dims );
elseif ~size_ambig( otp_dims ),
    A_x = tfocs_zeros( otp_dims );
    x0 = apply_linear( A_x, 2 );
end
if isempty( x0 ),
    error( 'Could not determine the dimensions of the problem. Please supply an explicit value for x0.' );
end
x = x0;
if isinf( C_x ),
    C_x = apply_projector( x );
    if isinf( C_x ),
        zero_x0 = false;
        [ C_x, x ] = apply_projector( x, 1 );
    end
end
if isempty( A_x ),
    if identity_linop || zero_x0 && square_linop,
        A_x = x;
    elseif ~zero_x0 || size_ambig( otp_dims ),  % Jan 2012: todo: give size_ambig the 'offset' information
        A_x = apply_linear( x, 1 ); % celldisp( size(A_x) )
    else
        A_x = tfocs_zeros( otp_dims );
    end
end

% New, Jan 2012
if debug
    if ~adjoint, str1 = 'primal'; str2 = 'dual';
    else, str1 = 'dual'; str2 = 'primal'; 
    end
    fprintf(fid,'------- DEBUG INFO -----------\n');
    offsetPossible  = offset && ~adjoint;
    fprintf(fid,'Size of %s variable, via method 1\n', str1);
    print_cell_size( size(x0), fid, offsetPossible);
    fprintf(fid,'Size of %s variable, via method 2\n', str1);
    print_cell_size( inp_dims, fid, offsetPossible);    
    
    offsetPossible  = offset && adjoint;
    fprintf(fid,'Size of %s variable, via method 1\n', str2);
    print_cell_size( size(A_x), fid, offsetPossible);
    fprintf(fid,'Size of %s variable, via method 2\n', str2);
    print_cell_size( otp_dims, fid, offsetPossible); 
    fprintf(fid,'------------------------------\n');
end
% Added Dec 2012, check for bad sizes that are not integers
if ~isequal( otp_dims, tfocs_round(otp_dims) )
    error('Output dimensions must be integer valued');
end
if ~isequal( inp_dims, tfocs_round(inp_dims) )
    error('Input dimensions must be integer valued');
end

% Final size check
[ isOK1, inp_dims ] = size_compat( size(x0), inp_dims );
[ isOK2, otp_dims ] = size_compat( size(A_x), otp_dims );
if ~isOK1 || ~isOK2,
    if debug
        if ~isOK1
            fprintf(fid,'Debug message: size of %s variables did not line up\n',str1);
        end
        if ~isOK2
            fprintf(fid,'Debug message: size of %s variables did not line up\n',str2);
        end
    end
    error( 'Could not determine the dimensions of the problem. Please supply an explicit value for x0.' );
end
[ f_x, g_Ax ] = apply_smooth( A_x );
if isinf( f_x ),
    error( 'The initial point lies outside of the domain of the smooth function.' );
end
% Adding Feb 2011: 
if isa(g_Ax,'tfocs_tuple')
    get_dual = @(g_Ax) get( g_Ax, saddle_ndxs );
else
    get_dual = @(g_Ax) g_Ax;
end

% Theta advancement function
% if mu > 0 && Lexact > mu 
if mu > 0 && ~isinf(Lexact) && Lexact > mu, % fixed Dec 2011
    if ~strcmp(alg,'N83')
        warnState = warning('query','backtrace');
        warning off backtrace
        warning('TFOCS:OptionsStructure',' Lexact and mu>0 specifications only give guaranteed convergence with N83 algorithm');
        if strcmp(alg,'AT')
            warning('TFOCS:OptionsStructure',' (With AT algorithm, known to give wrong solutions sometimes when mu>0)');
        end
        warning(warnState);
    end
    % Note that we have not yet derived theory to adapt this to
    %   a local Lipschitz constant but that it should be possible
    theta_scale = sqrt(mu / Lexact);
    theta_scale = ( 1 - theta_scale ) / ( 1 + theta_scale );
    advance_theta = @(theta_old,L,L_old) min(1,theta_old*theta_scale);
else
    advance_theta = @(theta_old,L,L_old) 2/(1+sqrt(1+4*(L/L_old)/theta_old.^2));
end

% Preallocate the arrays for the output structure
out.alg = alg; 
out.algorithm = algorithm;
if ~isempty(errFcn) && ~iscell(errFcn),
   errFcn = { errFcn };
end
if ~isempty(stopFcn) && ~iscell(stopFcn),
   stopFcn = { stopFcn };
end
errs = zeros(1,length(errFcn));
if nargoutt == 1,
    saveHist = false;
end
if saveHist,
    [ out.f, out.normGrad, out.stepsize, out.theta ] = deal( zeros(0,1) );
    if countOps,
        out.counts = zeros(0,length(tfocs_count___));
    end
    if ~isempty(errFcn),
        out.err = zeros(0,length(errs));
    end
end
if saddle,
    out.dual = [];
end
n_iter = 0;
status = '';

% Initialize the iterate values
y    = x;    z    = x;
A_y  = A_x;  A_z  = A_x;
C_y  = Inf;  C_z  = C_x;
f_y  = f_x;  f_z  = f_x;
g_y  = g_x;  g_z  = g_x;
g_Ay = g_Ax; g_Az = g_Ax;
norm_x = sqrt( tfocs_normsq( x ) );

% for recomputing linear operators
cntr_Ay     = 0;
cntr_Ax     = 0;

% Special setup for constant step sizes
if beta >= 1,
    beta = 1;
	alpha = 1;
end

% Print the opening text
if fid && printEvery,
	fprintf(fid,'%s\n',algorithm);
	fprintf(fid,'Iter    Objective   |dx|/|x|    step');
    if countOps, fprintf( fid, '       F     G     A     N     P' ); end
    if ~isempty(errFcn)
        nBlanks = max( [0, length(errFcn)*9 - 9] );
        fprintf( fid, '      errors%s',repmat(' ',nBlanks,1) ); 
    end
    if printStopCrit, fprintf( fid, '    stopping criteria' ); end
    fprintf( fid, '\n' );
	fprintf(fid,'----+----------------------------------' );
    if countOps, fprintf( fid, '+-------------------------------' ); end
%     if ~isempty(errFcn), fprintf( fid, '+-------------------' ); end
    if ~isempty(errFcn)
        fprintf( fid, '+%s', repmat('-',1+length(errFcn)*9,1) );
    end
    
    
    if printStopCrit, fprintf( fid, '+%s', repmat('-',19,1) ); end
    
    
    fprintf(fid,'\n');
end

% Initialize some variables
just_restarted = false;

% TFOCS v1.3 by Stephen Becker, Emmanuel Candes, and Michael Grant.
% Copyright 2013 California Institute of Technology and CVX Research.
% See the file LICENSE for full license information.

