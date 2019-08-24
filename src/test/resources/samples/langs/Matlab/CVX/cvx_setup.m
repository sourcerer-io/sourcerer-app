function cvx_setup( varargin )

% CVX_SETUP   Sets up and tests the cvx distribution.
%    This function is to be called any time CVX is installed on a new machine,
%    to insure that the paths are set properly and the MEX files are compiled.

global cvx___
try 

    cvx___ = [];
    squares = {}; %#ok
    nret = false;
    oldpath = '';
    line = '---------------------------------------------------------------------------'; 

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Get version and portability information %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    cvx_version( '-install', varargin{:} );
    if ~isfield( cvx___, 'loaded' ) || ~cvx___.loaded, %#ok
        error( 'CVX:Expected', 'Error detected by cvx_version' );
    end
    isoctave = cvx___.isoctave;
    mpath = cvx___.where;
    fs = cvx___.fs;
    ps = cvx___.ps;

    %%%%%%%%%%%%%%%%%%%%%%%
    % Reset the CVX paths %
    %%%%%%%%%%%%%%%%%%%%%%%
    
    oldpath = cvx_startup( false );
    if ~isempty( oldpath ),
        fprintf( 'Saving updated path...' ); 
        nret = true;
        s = warning('off'); %#ok
        stat = savepath;
        warning(s);
        if stat,
            fprintf('failed. (see below)\n');
        else
            fprintf('done.\n');
            oldpath = [];
        end
    end
    
    %%%%%%%%%%%%%%%%%%%%%%
    % Search for solvers %
    %%%%%%%%%%%%%%%%%%%%%%

    try
        selected = cvx___.solvers.names{cvx___.solvers.map.default};
    catch
        selected = 'sdpt3';
    end
    cvx___.solvers = struct( 'selected', 0, 'active', 0, 'list', [], 'names', {{}}, 'map', struct( 'default', 0 ) );
    fprintf( 'Searching for solvers...' ); nret = true;
    shimpath = [ mpath, fs, 'shims', fs ];
    solvers = dir( shimpath );
    solvers = { solvers(~[solvers.isdir]).name };
    if isoctave, efilt = '\.m$'; else efilt = '\.(m|p)$'; end
    solvers = solvers( ~cellfun( @isempty, regexp( solvers, efilt ) ) );
    solvers = unique( cellfun( @(x)x(1:end-2), solvers, 'UniformOutput', false ) );
    solvers = struct( 'name', '', 'version', '', 'location', '', 'fullpath', '', 'error', '', 'warning', '', 'dualize', '', 'path', '', 'check', [], 'solve', [], 'settings', [], 'sname', solvers, 'spath', shimpath, 'params', [], 'eargs', {{}} );
    solver2 = which( 'cvx_solver_shim', '-all' );
    if ~isempty(solver2) && ~iscell(solver2),
        solver2 = { solver2 };
    end
    for k = 1 : length(solver2),
        tsolv = solver2{k};
        ndxs = find(tsolv==fs,1,'last');
        solvers(end+1).spath = tsolv(1:ndxs); %#ok
        solvers(end).sname = tsolv(ndxs+1:end-2);
    end
    cur_d = pwd;
    nsolvers = [];
    nshims = length(solvers);
    for k = 1 : nshims,
        tsolv = solvers(k);
        try
            cd(tsolv.spath);
            tsolv = feval( tsolv.sname, tsolv );
            nsolv = length(tsolv);
            if nsolv > 1,
               sndx = 0;
                for e = 0 : 1,
                    for j = 1 : nsolv,
                        if e ~= isempty( tsolv(j).error ),
                            sndx = sndx + 1;
                            if sndx > 1, tsolv(j).name = sprintf( '%s_%d', tsolv(j).name, sndx ); end
                        end
                    end
                end
            end
        catch errmsg
            errmsg = cvx_error( errmsg, 63, false, '  ' );
            if isempty( tsolv.name ),
                tsolv.name = [ tsolv.spath, tsolv.sname ];
            end
            tsolv.error = sprintf( 'unexpected error:\n%s', errmsg );
        end
        nsolvers = [ nsolvers, tsolv ]; %#ok
    end
    solvers = nsolvers;
    cd( cur_d );
    
    %%%%%%%%%%%%%%%%%%%%%%%%%
    % Process solver errors %
    %%%%%%%%%%%%%%%%%%%%%%%%%
    
    plurals = { 's', '', 's' };
    nsolv = length(solvers);
    nrej = sum(~cellfun(@isempty,{solvers.error}));
    nwarn = sum(~cellfun(@isempty,{solvers.warning}));
    fprintf( '%d shim%s found.\n', nshims, plurals{min(nshims+1,3)} ); nret = false;
    lens = [ 0, 0 ];
    for k = 1 : nsolv,
        lens = max( lens, [ length(solvers(k).name), length(solvers(k).version) ] );
    end
    fmt = sprintf( ' %%s  %%-%ds   %%-%ds    %%s\\n', lens(1), lens(2) );
    if nsolv > nrej,
        fprintf( '%d solver%s initialized (* = default):\n', nsolv-nrej, plurals{min(nsolv-nrej+1,3)} );
        stats =  { ' ', '*' };
        for k = 1 : nsolv,
            if isempty( solvers(k).error ),
                fprintf( fmt, stats{1+strcmpi(solvers(k).name,selected)}, solvers(k).name, solvers(k).version, solvers(k).location );
            end
        end
    end
    if nrej,
        fprintf( '%d solver%s skipped:\n', nrej, plurals{min(nrej+1,3)} );
        for k = 1 : nsolv,
            if ~isempty( solvers(k).error ),
                fprintf( fmt, ' ', solvers(k).name, solvers(k).version, solvers(k).location ); %#ok
                cvx_error( solvers(k).error, 63, false, '        ' );
            end
        end
    end
    if nwarn,
        fprintf( '%d solver%s issued warnings:\n', nwarn, plurals{min(nwarn+1,3)} );
        for k = 1 : nsolv,
            if ~isempty( solvers(k).warning ) && isempty( solvers(k).error ),
                fprintf( fmt, ' ', solvers(k).name, solvers(k).version, solvers(k).location ); %#ok
                cvx_error( solvers(k).warning, 63, false, '        ' );
            end
        end
    end
    if nrej == nsolv,
        fprintf( [ ... 
            'No valid solvers were found. This suggests a corrupt installation. Please\n', ...
            'try re-installing the files and re-running cvx_setup. If the same error\n', ...
            'occurs, please contact CVX support.\n' ] );
        error('CVX:Unexpected','No valid solvers were found.');
    end
    solvers = solvers(cellfun(@isempty,{solvers.error}));
    cvx___.solvers.list  = solvers;
    cvx___.solvers.names = { solvers.name };
    cvx___.solvers.map   = struct( 'default', 0 );
    for k = 1 : length(solvers),
        cvx___.solvers.map.(lower(solvers(k).name)) = k;
        if strcmpi( solvers(k).name, selected ),
            cvx___.solvers.map.default = k;
            cvx___.solvers.selected = k;
        end
    end
    if cvx___.solvers.selected == 0,
        cvx___.solvers.selected = 1;
        cvx___.solvers.map.default = 1;
        fprintf( [ ...
            'WARNING: The default solver %s is missing; %s has been selected as a\n', ...
            '    new default. If this was unexpected, try re-running cvx_setup.\n' ], ...
            selected, cvx___.solvers.list(cvx___.solvers.selected).name, lower(cvx___.solvers.list(cvx___.solvers.selected).name) );
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Create the global data structure %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    cvx_global;
    if isempty( cvx___.solvers.list ),
        error('CVX:Unexpected','No valid solvers were found.');
    end
    
    %%%%%%%%%%%%%%%%%%%%
    % Save preferences %
    %%%%%%%%%%%%%%%%%%%%
    
    fprintf( 'Saving updated preferences...' ); nret = true;
    try
        cvx_save_prefs( 'save' );
        fprintf( 'done.\n' ); nret = false;
    catch errmsg
        fprintf( 'unexpected error:\n' ); nret = false;
        cvx_error( errmsg, 67, true, '    ' );
        fprintf( 'Please attempt to correct this error and re-run cvx_setup. If you cannot,\n' );
        fprintf( 'you will be forced to re-run cvx_setup every time you start MATLAB.\n' );
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%
    % Test the distribution %
    %%%%%%%%%%%%%%%%%%%%%%%%%

    fprintf( 'Testing with a simple model...' ); nret = true;
    need_cc = false;
    try
        m = 16; n = 8;
        A = randn(m,n);
        b = randn(m,1);
        cvx_begin('quiet')
            variable('x(n)');
            minimize( norm(A*x-b,1) );
        cvx_end
        fprintf( 'done!\n' ); nret = false;
    catch exc
        if any(strfind(exc.message,'clear classes')),
            fprintf( 'problem (see below).\n' );
            need_cc = true;
        else
            rethrow( exc );
        end
    end
        
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Quick instructions on changing the solver %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    if length( cvx___.solvers.list ) > 1,
        fprintf( '%s\n', line );
        fprintf( 'To change the default solver, type "cvx_solver <solver_name>".\n')
        fprintf( 'To save this change for future sessions, type "cvx_save_prefs".\n' );
        fprintf( 'Please consult the users'' guide for more information.\n' );
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Instruct the user to save the path %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    if ~isempty( oldpath )
        need_upr = false;
        need_disclaim = true;
        user_path = which( 'startup.m' );
        if isempty( user_path ),
            user_path = userpath;
            if length(user_path) <= 1,
                need_upr = true;
                user_path = system_dependent('getuserworkfolder', 'default');
                if ~isempty( user_path ),
                    if isempty( strfind( user_path, [ fs, 'MATLAB' ] ) ),
                        user_path = [ user_path, fs, 'MATLAB' ];
                    end
                end
            elseif user_path(end) == ps,
                user_path(end) = '';
            end
            if ~isempty( user_path ),
                user_file = [ user_path, fs, 'startup.m' ];
            else
                user_file = '';
            end
        else
            user_file = user_path;
            user_path = user_path(1:end-10);
        end
        fprintf( '%s\n', line );
        fprintf('NOTE: the MATLAB path has been changed to point to the CVX distribution. To\n' );
        fprintf('use CVX without having to re-run CVX_SETUP every time MATLAB starts, you\n' );
        fprintf('will need to save this path permanently. This script attempted to do this\n' );
        if fs == '/',
            fprintf('for you, but failed---likely due to UNIX permissions restrictions.\n' );
            nextword = 'To solve the problem';
        else
            fprintf('for you, but failed, due to the Windows User Access Control (UAC) settings.\n');
            fprintf('<a href="http://www.mathworks.com/support/solutions/en/data/1-9574H9/index.html?solution=1-9574H9">Click here</a> for a MATLAB document that discusses the issue.\n\n');
            fprintf('To solve this problem, please take the following steps:\n');
            fprintf('    1) Exit MATLAB.\n');
            fprintf('    2) Right click on the MATLAB icon, and select "Run as administrator."\n' );
            fprintf('    3) Re-run "cvx_setup".\n\n');
            nextword = 'Alternatively, if you do not have administrator access';
        end
        if exist( user_file, 'file' ),
            fprintf( '%s, edit the file\n    %s\nand add the following line to the end of the file:\n', nextword, user_file ); 
            fprintf( '    run %s%scvx_startup.m\n', mpath, fs );
        elseif ~isempty( user_path ),
            fprintf( '%s, create a new file\n    %s\ncontaining the following line:\n', nextword, user_file );
            fprintf( '    run %s%scvx_startup.m\n', mpath, fs );
        else
            fprintf( '%s, create a startup.m file containing the line:\n', nextword );
            fprintf( '    run %s%scvx_startup.m\n', mpath, fs );
            fprintf( 'Consult the MATLAB documentation for the proper location for that file.\n' );
            need_disclaim = false;
        end
        if need_upr,
            fprintf( 'Then execute the following MATLAB commands:\n    userpath reset; startup\n' );
        end
        if need_disclaim,
            fprintf( 'Please consult the MATLAB documentation for more information about the\n' );
            fprintf( 'startup.m file and its proper placement and usage.\n' );
        end
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Warn about class conflict with previous version of CVX %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    if need_cc,
        fprintf( '%s\n', line );
        fprintf('WARNING: CVX was unable to run the test model due to a conflict with the\n' );
        fprintf('previous version of CVX. If no other errors occurred, then the setup was\n' );
        fprintf('still successful; however, to use CVX, you will need to re-start MATLAB.\n' );
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Warn about signal processing toolbox conflict %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    squares = which( 'square', '-all' );
    if iscell( squares ) && length( squares ) > 1,
        squares = squares(~cellfun(@(x)any(strfind(x,[fs,'@cvx',fs])),squares));
        if length(squares) == 1 || ~strncmp(squares{1},[mpath,fs],length(mpath)+1),
            squares = {};
        end
    else
        squares = {};
    end
    if ~isempty(squares),
        fprintf( '%s\n', line );
        fprintf('WARNING: CVX includes a function\n    %s\n', squares{1} );
        fprintf('that conflicts with a function of the same name found here:\n    %s\n', squares{2} );
        fprintf('If you wish to use this second function, you will need to rename or delete\n' );
        fprintf('the CVX version, as it will likely produce different results. This will not\n' );
        fprintf('affect the use of SQUARE() within CVX models, because CVX relies on a\n' );
        fprintf('different, internal version of SQUARE() when constructing CVX models.\n')
    end

catch errmsg

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Restore the environment in the event of an error %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    if nret, fprintf( '\n' ); end
    switch errmsg.identifier,
        case { 'CVX:Expected', 'CVX:Licensing' },
            unexpected = false;
            if ~isempty( errmsg.message ),
                cvx_error( errmsg, 67, 'ERROR: ', '    ' );
            end
        case 'CVX:Unexpected',
            unexpected = true;
        otherwise,
            cvx_error( errmsg, 67, 'UNEXPECTED ERROR: ', '    ' );
            unexpected = true;
    end
    if ~isempty( oldpath ),
        path( oldpath );
    end
    clear global cvx___
    if unexpected,
        fprintf( 'Please report this error to support, and include entire output of\n' );
        fprintf( 'CVX_SETUP in your support request.\n' );
    else
        fprintf( 'The installation of CVX was not completed. Please correct the error\n' );
        fprintf( 'and re-run CVX_SETUP.\n' );
    end

end

fprintf( '%s\n\n', line );

% Copyright 2005-2016 CVX Research, Inc.
% See the file LICENSE.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.
