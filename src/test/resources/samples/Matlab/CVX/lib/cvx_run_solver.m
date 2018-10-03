function varargout = cvx_run_solver( sfunc, varargin )
global cvx___
settings_arg = varargin{end};
settings     = varargin{end-1};
inputs       = varargin(1:end-nargout-2);
dumpfile = '';
custom_on = false;
if isstruct( settings ),
    for f = fieldnames( settings )',
        sval = settings.(f{1});
        if isequal( f{1}, 'dumpfile' ),
            dumpfile = sval;
        else
            custom_on = true;
            inputs{settings_arg}.(f{1}) = sval;
        end
    end
end
if custom_on,
    fprintf( 'NOTE: custom settings have been set for this solver.\n' );
end
if ~isempty( dumpfile ),
    if ~ischar( dumpfile ) || size( dumpfile, 1 ) > 1,
        error( 'CVX:Dumpfile', 'Invalid filename for the dumpfile.' );
    elseif length(dumpfile) < 4 || ~strcmpi(dumpfile(end-3:end),'.mat'),
        dumpfile = [ dumpfile, '.mat' ];
    end
    fprintf( 'Saving output to: %s\n', dumpfile );
    fprintf( '------------------------------------------------------------\n');
    inp_names = cell(1,length(inputs));
    for k = 1 : length(inp_names),
        inp_names{1,k} = inputname(k+1);
    end
    dstruct = cell2struct( inputs, inp_names, 2 ); %#ok
    save( dumpfile, '-struct', 'dstruct' );
    diaryfile = [ dumpfile, '.txt' ];
    fid = fopen( diaryfile, 'w+' );
    if fid ~= 0,
        fclose( fid );
        diary( diaryfile );
    end
elseif custom_on,
    fprintf( '------------------------------------------------------------\n');
end
errmsg = [];
if cvx___.isoctave,
    fflush(1);
end
try
   [ varargout{1:nargout} ] = sfunc( inputs{:} );
catch errmsg
   [ varargout{1:nargout} ] = deal( [] );
end
if ~isempty( dumpfile ),
    if fid ~= 0,
        diary( 'off' );
        fid = fopen( diaryfile, 'r' );
        if fid ~= 0,
            output = fread( fid, Inf, '*char' )';
            fclose( fid );
            delete( diaryfile );
        end
    end
    if fid == 0,
        output = '<Could not save>';
    end
    otp_names = varargin(end-nargout-1:end-2);
    dstruct = cell2struct( [ inputs, varargout, output ], [ inp_names, otp_names, 'output' ], 2 ); %#ok
    save( dumpfile, '-struct', 'dstruct' );
end
if ~isempty( errmsg ),
    rethrow( errmsg );
end

% Copyright 2005-2016 CVX Research, Inc. 
% See the file LICENSE.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.
