function prevpath = cvx_startup( quiet )

%CVX_STARTUP   Quietly add CVX to your MATLAB path (for startup).
%    Running CVX_STARTUP upon startup ensures that CVX is properly included
%    in your MATLAB path.
%
%    On Mac and PC systems, this function is not necessary, because you can
%    simply run "savepath" to save the CVX path changes permanently, or use
%    the "pathtool" command to do the same. In fact, CVX_SETUP attempts to
%    run "savepath" as part of its setup process.
%
%    On UNIX systems, the MATLAB installation is usually installed in such
%    a manner that individual users cannot change the global MATLAB path.
%    This can be circumvented by making the PATHDEF.M file world-writable;
%    but if the system serves multiple users, this may not be desirable.
%
%    CVX_STARTUP provides a simple solution to this problem. Simply add the
%    following line to the end of your local STARTUP.M file:
%        run <full_path_to_CVX>/cvx_startup
%    Note that using the "run" command *and* providing the full path to the
%    CVX installation are critical. With this change, CVX_STARTUP.M will be
%    called every time the user runs MATLAB.
%
%    Note that CVX_STARTUP is *not* a substitute for running CVX_SETUP.
%    Please run CVX_SETUP first when installing CVX, and *then* add the
%    CVX_STARTUP line if instructed to do so.

global cvx___
if nargin < 1 || isempty( quiet ), 
    quiet = false; 
end
if ~quiet,
    fprintf( 'Setting CVX paths...' );
end
cvx_version(1);
fs = cvx___.fs;
ps = cvx___.ps;
cs = cvx___.cs;
mpath = cvx___.where;
msub = cvx___.msub;

prevpath = path;
oldpath = textscan( prevpath, '%s', 'Delimiter', ps );
oldpath = oldpath{1}(:)';
other_homes = which( 'cvx_setup.m', '-all' );
if ~iscell( other_homes ), other_homes = { other_homes }; end
other_homes = regexprep( other_homes, '.cvx_setup\.m$', '' );
other_homes( strcmp( other_homes, mpath ) ) = [];
ndxs = false(size(oldpath));
for k = 0 : length(other_homes),
    if k, tpath = other_homes{k}; else tpath = mpath; end
    plen = length(tpath);
    if cs, tndxs = strncmp( tpath, oldpath, plen );
    else tndxs = strncmpi( tpath, oldpath, plen ); end
    tndxs(tndxs) = cellfun(@(x)length(x)<=plen||x(plen+1)==fs,oldpath(tndxs));
    ndxs = ndxs | tndxs;
end
dndx = find(ndxs,1) - 1;
if isempty(dndx),
    dndx = +strcmp(oldpath{1},'.');
end
changed = false;
if any(ndxs),
    changed = true;
    newpath = horzcat( oldpath(~ndxs) );
    npath = sprintf( [ '%s', pathsep ], newpath{:} );
    npath = npath(1:end-1);
    path(npath);
end

addpaths = { 'builtins', 'commands', 'functions', 'lib', 'structures' };
mpath2 = mpath + fs; npath2 = length(mpath2);
if ~any(~strncmp(which('vec', '-all'), mpath2, npath2)),
    addpaths{end+1} = [ 'functions', fs, 'vec_' ]; 
end
if ~any(~strncmp(which('square', '-all'), mpath2, npath2)),
    addpaths{end+1} = [ 'functions', fs, 'square_' ]; 
end
if ~any(~strncmp(which('narginchk', '-all'), mpath2, npath2)),
    addpaths{end+1} = [ 'lib', fs, 'narginchk_' ]; 
end
addpaths = strcat( [ mpath, fs ], addpaths );
if ~isempty(msub),
  mpath2 = [ mpath, fs, 'lib', fs, msub ];
  if exist( mpath2, 'dir' ),
    addpaths{end+1} = mpath2;
  end
end
addpaths{end+1} = mpath;

ndxs(1:dndx) = true;
newpath = horzcat( oldpath(1:dndx), addpaths, oldpath(~ndxs) );
if changed || ~isequal( newpath, oldpath ),
    npath = sprintf( [ '%s', pathsep ], newpath{:} );
    npath = npath(1:end-1);
    path(npath);
end
if ~quiet,
    if isequal( newpath, oldpath ),
        fprintf( 'already set!\n' );
    else
        fprintf( 'done.\n' );
    end
    if ~isempty( other_homes ),
        fprintf( 'WARNING: other CVX installations were found in your MATLAB path:\n' );
        fprintf( '    %s\n', other_homes{:} );
        fprintf( 'They have been removed to prevent conflicts.\n' );
    end
end
if nargout,
    if isequal( npath, prevpath ),
        prevpath = '';
    end
else
    clear prevpath
end
cpath = struct('string','','active',false,'hold',false);
subs = strcat([mpath,fs],{'keywords','sets'});
cpath.string = sprintf( ['%s',ps], subs{:} );
cvx___.path = cpath;

% Copyright 2005-2016 CVX Research, Inc.
% See the file LICENSE.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.
