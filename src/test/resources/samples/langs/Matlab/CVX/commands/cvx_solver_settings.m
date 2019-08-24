function sout = cvx_solver_settings( varargin )

%CVX_SOLVER_SETTINGS    CVX solver settings adjustment.
%   CVX_SOLVER_SETTINGS is used to adjust the advaned settings of the 
%   current solver being used by CVX. Before using this function, please 
%   read the IMPORTANT NOTE below.
%
%   CVX_SOLVER_SETTINGS( <name1>, <value1>, [ <name2>, <value2>, ... ] )
%   stores a custom setting called <name1> for the active solver, and gives
%   it a value of <value2>, and so forth for the other key-value pairs.
%   Each name must be a string containing a valid variable name; the values
%   may be of any type or size, including empty arrays or strings.
%
%   When CVX_END is reached, these key/value pairs will be delivered to the
%   underlying solver as parameters. This allows an expert user to modify
%   the behavior of the underlying solver in a manner that is otherwise
%   unavailable through more standard CVX commands.
%
%   CVX_SOLVER_SETTINGS( 'name' ) or
%   CVX_SOLVER_SETTINGS name
%   returns the current value of that setting for the current solver. If
%   there is no such setting by that name, an error results.
%
%   CVX_SOLVER_SETTINGS( '-clear', <name1>, '-clear', <name2>, ... ) or
%   CVX_SOLVER_SETTINGS -clear <name>
%   Removes the key/value pair matching <name> from the settings list for 
%   the active solver.
%
%   CVX_SOLVER_SETTINGS, with no arguments, displays the current list of
%   settings for the active solver.
%
%   CVX_SOLVER_SETTINGS -all displays a list of the settings for all
%   all available solvers.
%
%   CVX_SOLVER_SETTINGS -clear clears all settings for the active solver.
%
%   CVX_SOLVER_SETTINGS -clearall clears all settings for all solvers.
%
%   CVX_SOLVER_SETTINGS( S )
%   where S is a structure, replaces the *entire* list of solver settings
%   with the field-value pairs stored in the structure S.
%
%   S = CVX_SOLVER_SETTINGS returns a structure containing all of the
%   settings for the current solver.
%
%   If you call CVX_SOLVER_SETTINGS within a model --- that is, between
%   CVX_BEGIN and CVX_END --- then the changes are "local": that is, they
%   will apply ONLY to the current model.
%
%   On the other hand, if you call CVX_SOLVER_SETTINGS outside of a model,
%   then the changes are "global": they will apply to all subsequent models
%   that employ that solver.
%
%   CVX_SAVE_PREFS will save any global settings you have provided, so they
%   will be restored the next time you start MATLAB.
%
%   CVX_SOLVER_SETTINGS( 'dumpfile', <filename> ) is a setting supported by
%   all solvers. If set, it will save a .MAT file containing the exact
%   input arguments delivered to the solver. This file will be created
%   immediately before the solver is called, so you will be able to examine
%   their contents even if the solver fails with an error. This feature is
%   to be used primarily by solver developers.
%
%   **** IMPORTANT NOTE ****
%   Please use this feature with extreme caution, and at your own risk:
%   * CVX does not check the correctness of the settings you supply. If the
%     solver rejects the setting you supply, CVX will fail until you change
%     or remove that setting.
%   * Use of this feature can alter the quality of the solutions that the
%     solver produces: sometimes for the better, sometimes for the worse.
%   * Please consult your solver's specific documentation for information
%     about its available settings.
%   * The settings set here *override* any default values CVX has chosen
%     for each solver. In certain cases, this may actually confuse CVX and
%     and cause it to misinterpret the results. Fpr this reason, we cannot
%     support all possible combinations of custom settings.
%
%   See also CVX_SOLVER, CVX_SAVE_PREFS, CVX_QUIET, CVX_PRECISION.

global cvx___
cvx_global
is_local = ~isempty( cvx___.problems );
if is_local,
    snumber = cvx___.problems(end).solver.index;
    settings = cvx___.problems(end).solver.settings;
else
    snumber = cvx___.solvers.selected;
    if isfield( cvx___.solvers.list, 'settings' ),
        settings = cvx___.solvers.list(snumber).settings;
    else
        settings = [];
    end
end
sname = cvx___.solvers.names{snumber};
update = false;
switch nargin,
    case 0,
        if is_local,
            fprintf( '\nLocal settings for solver %s:\n', sname );
        else
            fprintf( '\nGlobal settings for solver %s:\n', sname );
        end
        if isempty( settings ) || isempty( fieldnames( settings ) ),
            fprintf( '    No custom settings specified.\n\n' );
        else
            disp( settings );
        end
    case 1,
        t_setting = varargin{1};
        if isstruct( t_setting ),
            update = true;
            if numel( t_setting ) > 1,
                error( 'Argument must be a string or a scalar structure.' );
            elseif isempty( fieldnames( settings ) ),
                settings = [];
            else
                settings = t_setting;
            end
        elseif ~ischar( t_setting ) || isempty( t_setting ) || size( t_setting, 1 ) > 1,
            error( 'Argument must be a string or a scalar structure.' );
        else
            switch t_setting,
                case '-all',
                    fprintf( '\n' );
                    if is_local,
                        fprintf( 'Local settings for solver %s:\n', sname );
                        if isempty( settings ) || isempty( fieldnames( settings ) ),
                            fprintf( '    No custom settings specified.\n\n' );
                        else
                            disp( settings );
                        end
                    end
                    for k = 1 : length(cvx___.solvers.list),
                        fprintf( 'Global settings for solver %s:\n', cvx___.solvers.names{k} );
                        settings = cvx___.solvers.list(k).settings;
                        if isempty( settings ) || isempty( fieldnames( settings ) ),
                            fprintf( '    No custom settings specified.\n\n' );
                        else
                            disp( settings );
                        end
                    end
                case '-clear',
                    settings = [];
                    update = true;
                case '-clearall',
                    settings = [];
                    update = is_local;
                    [ cvx___.solvers.list.settings ] = deal( [] );
                otherwise,
                    if ~isvarname( t_setting ),
                        error( 'CVX:InvalidField', 'Not a valid setting name: %s', t_setting );
                    elseif isfield( settings, t_setting ),
                        settings = settings.(t_setting);
                    else
                        error( 'CVX:NoSetting', 'Setting %s is not set.', t_setting );
                    end
            end
        end
    otherwise,
        update = true;
        if rem( nargin, 2 ) ~= 0,
            error( 'Number of arguments must be even.' );
        end
        for k = 1 : nargin/2,
            t_setting = varargin{2*k-1};
            t_value = varargin{2*k};
            if ~ischar( t_setting ) || isempty( t_setting ) || size( t_setting, 1 ) > 1,
                error( 'CVX:InvalidField', 'Argument %d must be a string.', 2*k-1 );
            else
                switch t_setting,
                    case '-clear',
                        if ~isvarname( t_value ),
                            error( 'CVX:InvalidField', 'Not a valid setting name: %s', t_value );
                        elseif ~isfield( settings, t_value ),
                            error( 'CVX:NoSetting', 'Setting %s is not set.', t_setting );
                        else
                            settings = rmfield( settings, t_value );
                            update = true;
                        end
                    otherwise,
                        if ~isvarname( t_setting ),
                            error( 'CVX:InvalidField', 'Not a valid setting name: %s', t_setting );
                        else
                            settings.(t_setting) = t_value;
                            update = true;
                        end
                end
            end
        end
end
if update,
    if is_local,
        cvx___.problems(end).solver.settings = settings;
    else
        cvx___.solvers.list(snumber).settings = settings;
    end
end    
if nargout,
    sout = settings;
end

% Copyright 2005-2016 CVX Research, Inc.
% See the file LICENSE.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.
