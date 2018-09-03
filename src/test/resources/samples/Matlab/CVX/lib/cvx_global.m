function cvx_global

%CVX_GLOBAL   Create CVX's global internal data structure, if needed.
%   CVX_GLOBAL creates a hidden structure CVX needs to do its work. It is
%   harmless for the user to call it, but it is also useless to do so.

global cvx___ 
if isfield( cvx___, 'problems' ),
    return
end
tstart = tic;
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Initialize the global data structure %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

cvx_version(1);

commands = { 'cvx_begin', 'cvx_clear', 'cvx_end', 'cvx_expert', ...
    'cvx_pause', 'cvx_power_warning', 'cvx_precision', 'cvx_profile', ...
    'cvx_quiet', 'cvx_save_prefs' };
c_type = cell(1,length(commands));
[ c_type{:} ] = deal('C');
keywords = { 'in', 'dual', 'epigraph', 'expression', 'expressions', ...
    'hypograph', 'maximize', 'maximise', 'minimize', 'minimise', ...
    'subject', 'variable', 'variables' };
k_type = cell(1,length(keywords)); 
[ k_type{:} ] = deal('K');
structures = { 'banded', 'binary', 'complex', 'diagonal', 'hankel', ...
    'hermitian', 'integer', 'lower_bidiagonal', 'lower_hessenberg', ...
    'lower_triangular', 'nonnegative', 'scaled_identity', ...
    'skew_symmetric', 'semidefinite', 'sparse', 'symmetric', ...
    'toeplitz', 'tridiagonal', 'upper_bidiagonal', 'upper_hankel', ...
    'upper_hessenberg', 'upper_triangular' };
s_type = cell(1,length(structures)); 
[ s_type{:} ] = deal('S');
reserved = cell2struct([c_type,k_type,s_type],[commands,keywords,structures],2);

cvx___.reswords    = reserved;
cvx___.problems    = [];
cvx___.id          = 0;
cvx___.pause       = false;
cvx___.quiet       = false;
cvx___.profile     = false;
cvx___.reserved    = 1;
cvx___.logarithm   = sparse( 1, 1 );
cvx___.exponential = sparse( 1, 1 );
cvx___.vexity      = 0; % sparse( 1, 1 );
cvx___.exp_used    = false;
cvx___.nan_used    = false;
cvx___.canslack    = false;
cvx___.readonly    = 0;
cvx___.needslack   = false(0,1);
cvx___.cones       = struct( 'type', {}, 'indices', {} );
cvx___.x           = zeros( 0, 1 );
cvx___.y           = zeros( 0, 1 );
temp = cvx( [0,1], [] );
cvx___.equalities  = temp;
cvx___.linforms    = temp;
cvx___.linrepls    = temp;
cvx___.uniforms    = temp;
cvx___.unirepls    = temp;
try
    cvx___.timers = zeros(1,4,'uint64');
    cvx___.timers(1) = cvx___.timers(1) + tstart;
catch
    cvx___.timers = [double(tstart),0,0,0];
end
cvx___.increment   = [];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Run each shim to connect/reconnect the solvers %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

cur_d = pwd;
osolvers = cvx___.solvers.list;
solvers = struct( 'name', {}, 'version', {}, 'location', {}, 'fullpath', {}, 'error', {}, 'warning', {}, 'dualize', {}, 'path', {}, 'check', {}, 'solve', {}, 'settings', {}, 'sname', {}, 'spath', {}, 'params', {}, 'eargs', {} );
nsolv = length(osolvers);
nrej = 0;
for k = 1 : length(osolvers),
    tsolv = osolvers(k);
    try
        cd(tsolv.spath);
        tsolv.warning = '';
        tsolv = feval(tsolv.sname,tsolv);
    catch errmsg
        errmsg = cvx_error( errmsg, 63, false, '    ' );
        if isempty( tsolv.name ),
            tsolv.name = [ tsolv.spath, tsolv.sname ];
        end
        tsolv.error = sprintf( 'unexpected error:\n%s', errmsg );
    end
    if ~isempty(tsolv.error),
        nrej = nrej + 1;
    end
    try
        solvers(k) = tsolv;
    catch
        for ff = fieldnames(tsolv)',
            solvers(k).(ff{1}) = tsolv.(ff{1});
        end
    end
end
clear osolvers
cvx___.solvers.list = solvers;
cd( cur_d );

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% If any solvers have errors, force the user to re-run cvx_setup. %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if ~nrej, return; end
reject = {};
reject_lic = {};
reject_java = {};
ndefault = 0;
for k = 1 : nsolv,
    if isempty( solvers(k).error ),
        if ~ndefault, ndefault = k; end
    elseif isequal( solvers(k).error, 'Java support is required.' );
        reject_java{end+1} = solvers.name; %#ok
    elseif isequal( solvers(k).error, 'A CVX Professional license is required.' ),
        reject_lic{end+1} = solvers(k).name; %#ok
    else
        errmsg = [ solvers(k).name, ': ', solvers(k).error ];
        reject{end+1} = cvx_error( errmsg, 67, false, '    ' ); %#ok
    end
end
if ~isempty( reject_java ),
    reject_java = sprintf( '%s ', reject_java{:} );
    warning( 'CVX:SolverErrors', 'The following solvers were disabled due to the disabling of Java: %s', reject_java );
end
if ~isempty( reject_lic ),
    reject_lic = sprintf( '%s ', reject_lic{:} );
    warning( 'CVX:SolverErrors', 'The following solvers are are disabled due to licensing issues: %s', reject_lic );
end
if ~isempty( reject ),
    reject = sprintf( '%s', reject{:} );
    warning( 'CVX:SolverErrors', 'The following errors were issued when initializing the solvers:\n%sPlease check your installation and re-run CVX_SETUP.\nThese solvers are unavailable for this session.%s', reject );
end
if nrej == length( solvers ),
    clear global cvx___
    error( 'CVX:SolverErrors', 'All solvers were disabled due to various errors.\nPlease re-run CVX_SETUP and, if necessary, contact CVX Research for support.' );
elseif ~isempty(solvers(cvx___.solvers.map.default).error),
    cvx___.solvers.map.default = ndefault;
    cvx___.solvers.selected = ndefault;
    warning( 'CVX:SolverErrors', 'The default solver has temporarily been changed to %s.', solvers(ndefault).name );
end

% Copyright 2005-2016 CVX Research, Inc.
% See the file LICENSE.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.
