function make( varargin )

%
% Determine the base path
%

odir = pwd;
base = mfilename('fullpath');
base = fileparts( base );

%
% Check the force and runonly flags
%

args = varargin;
is_octave = exist( 'OCTAVE_VERSION', 'builtin' );
if is_octave,
    force = true;
    runonly = true;
    indexonly = false;
    page_output_immediately(true);
else
    temp = strcmp( args, '-force' );
    force = any( temp );
    if force, args(temp) = []; end
    temp = strcmp( args, '-runonly' );
    runonly = any( temp );
    if runonly, args(temp) = []; end
    temp = strcmp( args, '-indexonly' );
    indexonly = any( temp );
    if indexonly, args(temp) = []; end
    if ~runonly,
      close all;
      fclose all;
    end
end
if isempty( args ), 
    args = { base }; 
end

%
% Process the arguments
%

for k = 1 : length( args ),
    file = args{k};
    if any( file == '*' ),
        files = dir( file );
        files = { files.name };
    else
        files = { file };
    end
    for j = 1 : length( files );

        %
        % Check the validity of the file or directory
        %

        file = files{j};
        switch exist( file, 'file' ),
            case 0,
                error( 'Cannot find file or directory: %s', file );
            case 2,
                file = which( file );
                if isempty( file ), 
                    file = files{j};
                    if file(1) ~= filesep,
                        file = [ base, filesep, file ];
                    end
                end
                [ mpath, file, ext ] = fileparts( file );
                file = [ file, ext ];
                if ~strcmp( ext, '.m' ),
                    error( 'Must be an m-file: %s' );
                elseif strcmp( file, 'Contents.m' ) && length( files ) > 1,
                    continue;
                elseif strcmp( file, 'make.m' ) && strcmp( mpath, base ),
                    continue;
                end
            case 7,
                cd( file );
                mpath = pwd;
                cd( odir );
                file = '';
            otherwise,
                error( 'Invalid file: %s', file );
        end
        if length( mpath ) < length( base ) || strncmpi( mpath, base, length( base ) ) == 0,
            error( 'Not a valid a subdirectory of cvx/examples/: %s', mpath );
        end

        %
        % Process the file or directory
        %

        if ~runonly && isempty( file ) && strcmp( mpath, base ),
            [ fidr, message ] = fopen( 'index.html', 'r' );
            if fidr < 0,
                error( 'Cannot open index.html\n   %s', message );
            end
            [ fidw, message ] = fopen( 'index.html.new', 'w+' );
            if fidw < 0,
                error( 'Cannot open index.html.new\n   %s', message );
            end
            while ~feof( fidr ),
                temp = fgetl( fidr );
                fprintf( fidw, '%s\n', temp );
                if strcmp(temp,'<ul class="mktree" id="tree1">'),
                    while ~feof( fidr ),
                        temp = fgetl( fidr );
                        if strcmp(temp,'</ul>'), break; end
                    end
                    break;
                end
            end
        else
            fidw = -1;
        end
        if isempty( file ),
            generate_directory( mpath, '', force, runonly, indexonly, fidw, base, 0, is_octave );
        else
            cd( mpath );
            generate_file( file, '', force, runonly, indexonly, is_octave );
        end
        cd( odir );
        if fidw >= 0,
            fprintf( fidw, '</ul>\n' );
            while ~feof( fidr ),
                fprintf( fidw, '%s\n', fgetl( fidr ) );
            end
            fclose( fidr );
            fclose( fidw );
            cd( mpath )
            compare_and_replace( '', 'index.html' );
        end
    end
end

function [ title, files ] = generate_directory( mpath, prefix, force, runonly, indexonly, fidc, base, depth, is_octave )

fprintf( 1, '%sDirectory: %s\n', prefix, mpath );
prefix = [ prefix, '   ' ];
cd( mpath );
mpath = pwd;

%
% Open Contents.m file and retrieve title and comments
%

title = '';
if ~runonly,
    comments = {};
    fcomments = {};
    [ fidr, message ] = fopen( 'Contents.m', 'r' );
    if fidr >= 0,
        temp = fgetl( fidr );
        if length( temp ) > 2 && temp( 1 ) == '%' && temp( 2 ) == ' ' && temp( 3 ) ~= ' ',
            title = temp( min( find( temp ~= '%' & temp ~= ' ' ) ) : end );
            while ~feof( fidr ),
                temp = fgetl( fidr );
                if isempty(temp) || temp( 1 ) ~= '%' || ~any( temp ~= '%' & temp ~= ' ' ), break; end
                temp = temp( min( find( temp ~= '%' & temp ~= ' ' ) ) : end );
                if strcmp(title(end-2:end),'...'),
                    title = [ title(1:end-3), temp ];
                else
                    if ~isempty(fcomments) && strcmp( fcomments{end}(end-2:end),'...' ),
                        fcomments{end} = [ fcomments{end}(1:end-3), temp ];
                    else
                        fcomments{end+1} = temp;
                    end
                    comments{end+1} = temp;
                end
            end
        end
        fclose( fidr );
    elseif ~isempty( dir( 'Contents.m' ) ),
        error( 'Cannot open Contents.m for reading\n   %s', message );
    end
end
if isempty(title),
    title = '(no title)';
end

%
% Read the entries, and process the scripts and functions
%

dd = dir;
mlen = 0;
files = struct( 'name', {}, 'title', {}, 'type', {} );
for k = 1 : length( dd ),
    name = dd(k).name;
    if dd(k).isdir,
        if name(1) == '.' || strcmp( name, 'eqs' ) || strcmp( name, 'html' ), continue; end
        name(end+1) = '/';
        files( end + 1 ) = struct( 'name', name, 'title', '', 'type', 'dir' );
    elseif length( name ) > 2,
        ndx = max(find(name=='.'));
        if isempty( ndx ), continue; end
        switch name(ndx+1:end),
            case 'm',
                if strcmp( name, 'Contents.m' ) || strcmp( name, 'make.m' ) || name(end-2) == '_', continue; end
                [ temp, isfunc ] = generate_file( name, prefix, force, runonly, indexonly, is_octave );
                if isfunc, type = 'func'; else type = 'script'; end
                files( end + 1 ) = struct( 'name', name, 'title', temp, 'type', type );
            case 'tex',
                temp = generate_doc( name, prefix, force );
                files( end + 1 ) = struct( 'name', name, 'title', temp, 'type', 'tex' );
            case { 'pdf', 'ps' },
                if any( strcmp( { dd.name }, [name(1:ndx+1),'tex'] ) ), continue; end
                files( end + 1 ) = struct( 'name', name, 'title', '', 'type', 'doc' );
            case { 'dat', 'mat', 'txt' },
                if strcmp( name, 'index.dat' ), continue; end
                files( end + 1 ) = struct( 'name', name, 'title', '', 'type', 'dat' );
            otherwise,
                continue;
        end
    end
    mlen = max( mlen, length(name) );
end

%
% Sort the files
%

if ~isempty( files ),
    [ fnames, ndxs ] = sort( { files.title } );
    files = files(ndxs);
    ftypes = { files.type };
    tdir  = strcmp( ftypes, 'dir' );
    tfun  = strcmp( ftypes, 'func' );
    tdoc  = strcmp( ftypes, 'doc' ) | strcmp( ftypes, 'tex' );
    tdat  = strcmp( ftypes, 'dat' );
    tscr  = ~( tdir | tfun | tdoc | tdat );
    t1    = strncmp( fnames, 'Exercise', 8 ) & tscr;
    t2    = strncmp( fnames, 'Example',  7 ) & tscr;
    t3    = strncmp( fnames, 'Section',  7 ) & tscr;
    t4    = strncmp( fnames, 'Figure',   6 ) & tscr;
    t5    = ~( t1 | t2 | t3 | t4 ) & tscr;
    tdir  = find(tdir(:));
    tscr  = [ find(t3(:)); find(t4(:)); find(t2(:)); find(t5(:)); find(t1(:)); ];
    tfun  = find(tfun(:));
    tdoc  = find(tdoc(:));
    tdat  = find(tdat(:));
    files = files( [ tdoc ; tdir ; tscr ; tfun ; tdat ] );
    tdoc  = [ 1, length(tdoc) ];
    tdir  = tdoc(end) + [ 1, length(tdir) ];
    tscr  = tdir(end) + [ 1, length(tscr) ];
    tfun  = tscr(end) + [ 1, length(tfun) ];
    tdat  = tfun(end) + [ 1, length(tdat) ];
end

%
% Fill out the index.jemdoc file
%

if fidc >= 0,
    
    dots = sprintf('\t');
    dots = dots(ones(1,depth+1));
    dpath = mpath( length(base) + 2 : end );
    dpath(dpath=='\') = '/';
    if ~isempty(dpath), dpath(end+1) = '/'; end
    
    % Directory title---skip for the top level
    
    if depth,
        title = regexprep(title,'</?b>','');
        title = regexprep(title,' target="_blank"','');
        title2 = regexprep(title,'<a ([^>]*>)','</b><a target="_blank" $1<b>');
        title2 = regexprep(title2,'</a>','</b></a><b>');
        title2 = regexprep(['<b>',title2,'</b>'],'<b></b>','');
        fprintf( fidc, '%s<li>%s<ul>\n', dots(1:end-1), title2 );
    end
    
    if tdoc(2) >= tdoc(1) || ~isempty( fcomments ),
        for k = tdoc(1) : tdoc(2),
            name = files( k ).name;
            if strcmp( files(k).type, 'tex' ),
                name = [ name(1:end-4), 'pdf' ];
            end
            temp = files( k ).title;
            if isempty( temp ),
                fprintf( fidc, '%s<li>Reference: <a href="%s%s" target="_blank">%s</a></li>\n', dots, dpath, name, name );
            else
                fprintf( fidc, '%s<li>Reference: <a href="%s%s" target="_blank">%s (%s)</a></li>\n', dots, dpath, name, temp, name );
            end
        end
        for k = 1 : length(fcomments),
            fprintf( fidc, '%s<li>Reference: %s</li>\n', dots, regexprep(fcomments{k},'<a href=','<a target="_blank" href='));
        end
    end

    for k = tdir(1) : tdir(2),
        files(k).title = generate_directory( files(k).name(1:end-1), prefix, force, runonly, indexonly, fidc, base, depth+1, is_octave );
        cd(mpath);
    end
    
    if tscr(2) >= tscr(1),
        if ~depth,
            fprintf( fidc, '%s<li><b>Miscellaneous examples</b>\n', dots );
            dots(end+1) = dots(end);
            fprintf( fidc, '%s<ul>\n', dots );
        end
        for k = tscr(1) : tscr(2),
            name = files( k ).name;
            temp = files( k ).title;
            if isempty( temp ),
                fprintf( fidc, '%s<li><a href="%s%s">%s</a></li>\n', dots, dpath, name, name );
            else
                fprintf( fidc, '%s<li><a href="%shtml/%shtml">%s</a> (<a href="%s%s">%s</a>)</li>\n', dots, dpath, name(1:end-1), temp, dpath, name, name );
            end
        end
        if ~depth,
            fprintf( fidc, '%s</ul>\n', dots );
            dots(end) = [];
            fprintf( fidc, '%s</li>\n', dots );
        end
    end

    if tfun(2) >= tfun(1),
        pref = 'Utility: ';
        for k = tfun(1) : tfun(2),
            name = files( k ).name;
            temp = files( k ).title;
            if isempty( temp ),
                fprintf( fidc, '%s<li>Utility: <a href="%s%s">%s</a></li>\n', dots, dpath, name, name );
            else
                fprintf( fidc, '%s<li>Utility: <a href="%shtml/%shtml">%s</a> (<a href="%s%s">%s</a>)</li>\n', dots, dpath, name(1:end-1), temp, dpath, name, name );
            end
        end
    end
    
    if tdat(2) >= tdat(1),
        pref = '- Data: ';
        for k = tdat(1) : tdat(2),
            name = files( k ).name;
            temp = files( k ).title;
            if isempty( temp ),
                fprintf( fidc, '%s<li>Data: <a href="%s%s">%s</a></li>\n', dots, dpath, name, name );
            else
                fprintf( fidc, '%s<li>Data: <a href="%s%s">%s (%s)</a></li>\n', dots, dpath, name, temp, name );
            end
        end
    end
    
    if depth, 
        fprintf( fidc, '%s</ul></li>\n', dots(1:end-1) );
    end
        
elseif any( tdir ),
    
    for k = 1 : length( files ),
        if strcmp( files(k).type, 'dir' ),
            files(k).title = generate_directory( files(k).name(1:end-1), prefix, force, runonly, indexonly, fidc, base, depth+1, is_octave );
            cd(mpath);
        end
    end

end
        

%
% Create Contents.m.new
%

if ~runonly,
    [ fidw, message ] = fopen( 'Contents.m.new', 'w+' );
    if fidw < 0,
        if fidr >= 0, fclose( fidr ); end
        error( 'Cannot open Contents.m.new\n   %s', message );
    elseif ~isempty( title ),
        fprintf( fidw, '%% %s\n', title );
        for k = 1 : length( comments ),
            fprintf( fidw, '%% %s\n', comments{k} );
        end
        fprintf( fidw, '%%\n' );
    end
    for k = 1 : length( files ),
        tfile = files(k);
        tfile.name(end+1:mlen) = ' ';
        if isempty( tfile.title ),
            fprintf( fidw, '%%  %s - (no title)\n', tfile.name );
        else
            fprintf( fidw, '%%  %s - %s\n', tfile.name, tfile.title );
        end
    end
    fprintf( fidw, 'help Contents\n' );
    fclose( fidw );
else
    fidw = -1;
end

%
% Compare Contents.m and Contents.m.new and update if necessary
%

cd( mpath )
if fidw >= 0,
    compare_and_replace( prefix, 'Contents.m' );
end

function [ title, isfunc ] = generate_file( name, prefix, force, runonly, indexonly, is_octave )

if length( name ) < 2 || ~strcmp( name(end-1:end), '.m' ),
    error( 'Not an m-file.' );
elseif strcmp( name, 'Contents.m' ),
    error( 'To generate the Contents.m file, you must run this function on the entire directory.' );
else
    fprintf( 1, '%s%s: ', prefix, name );
end

dd = dir( name );
ndate = date_convert( dd.date );
[ fidr, message ] = fopen( name, 'r' );
if fidr < 0,
    error( 'Cannot open the source file\n   %s', message );
end
title = '';
isfunc = false;
lasttitle = false;
founddata = false;
prefixes = {};
while ~feof( fidr ) && ( ~founddata || isempty( title ) || lasttitle ),
    temp1 = fgetl( fidr );
    if isempty( temp1 ),
        if lasttitle, continue; end
    else
        temp2 = find( temp1 ~= ' ' );
        if isempty( temp2 ),
            if lasttitle, continue; end
        elseif temp1(temp2(1)) == '%',
            temp2 = temp1(temp2(1):temp2(end));
            temp3 = find( temp2 ~= '%' );
            if isempty( temp3 ),
                if lasttitle, continue; end
            else
                temp3 = temp2( temp3(1) : end );
                temp4 = find( temp3 ~= ' ' );
                if isempty( temp4 ),
                    if lasttitle, continue; end
                elseif isempty( title ),
                    title = temp3(temp4(1):temp4(end));
                    lasttitle = true;
                    continue;
                else
                    lasttitle = false;
                end
            end
        else
            lasttitle = false;
            founddata = true;
            temp2 = temp1(temp2(1):temp2(end));
            if strncmp( temp2, 'function', 8 ) && ( length( temp2 ) == 8 || ~isvarname( temp2( 1 : 9 ) ) ),
                isfunc = true;
            end
        end
    end
    prefixes{end+1} = temp1;
end
if runonly,
    fclose( fidr );
    if isfunc, return; end
end
hfile = [ name(1:end-1), 'html' ];
odir = pwd;
hdir = 'html';
hdate = 0;
if exist( hdir, 'dir' ),
    cd( hdir );
    df = dir( hfile );
    if length( df ) == 1,
        hdate = date_convert( df.date );
    end
    cd( odir );
end
if indexonly,
    fprintf( 1, 'done.\n' );
elseif force || hdate <= ndate,
    if runonly,
        fprintf( 1, 'running %s ...', name );
    elseif hdate == 0,
        fprintf( 1, 'creating %s ...', hfile );
    else
        fprintf( 1, 'updating %s ...', hfile );
    end
    name = name(1:end-2);
    if ~runonly,
        [ fidw, message ] = fopen( [ name, '_.m' ], 'w+' );
        if fidw < 0,
            error( 'Cannot open the temporary file\n   %s', message );
        end
        if isempty( title ),
            fprintf( fidw, '%%%% %s\n\n', name );
        else
            fprintf( fidw, '%%%% %s\n\n', title );
        end
        fprintf( fidw, '%s\n', prefixes{:} );
        fwrite( fidw, fread( fidr, Inf, 'uint8' ), 'uint8' );
        fclose( fidw );
        fclose( fidr );
    end
    evalin( 'base', 'clear' );
    cvx_clear;
    cvx_quiet( false );
    cvx_precision default;
    success = true;
    try
        out___ = [];
        if is_octave,
            run_clean_octave( name );
        elseif runonly,
            out___ = run_clean( name );
            fprintf( 1, ' done.\n' );
        else
            opts.format = 'html';
            opts.useNewFigure = false;
            opts.createThumbnail =  false;
            opts.evalCode = ~isfunc;
            opts.showCode = true;
            opts.catchError = false;
            publish( [ name, '_' ], opts );
            prefixes = { '<style', '<!--', '<p class="footer"', '<meta name=', '<link rel=' };
            suffixes = { '</style>', '-->', '</p>', '>', '>' };
            suffix = '';
            f_in = fopen( [ 'html', filesep, name, '_.html' ], 'r' );
            data = fread( f_in, Inf, 'uint8=>char' )';
            fclose( f_in );
            backpath = '';
            for k = 1 : 10,
                if exist( [ backpath, filesep, 'examples.css' ], 'file' ), break; end
                backpath = [ '..', filesep, backpath ];
            end
            backpath = [ '..', filesep, backpath ];
            canon = [regexprep(pwd,'.*/cvx/examples','http://cvxr.com/cvx/examples'),'/html/',hfile];
            data = regexprep( data, '<!--.*?-->|<link rel=.*?>|<style.*?</style>|<meta name=.*?>|<p class="footer".*?</p>', '' );
            data = regexprep( data, '</head>', sprintf( '\n<link rel="canonical" href="%s"/>\n<link rel="stylesheet" href="%sexamples.css" type="text/css"/>\n</head>', canon, backpath ) );
            data = regexprep( data, '<div class="content"><h1>(.*?)</h1>','<div id="header">\n<h1>$1</h1>\n<!--control--></div><div id="content">' );
            data = regexprep( data, '<pre class="codeinput">\n?', '\n<a id="source"></a><pre class="codeinput">\n' );
            if ~isempty( regexp( data, '<pre class="codeoutput">' ) ),
                control_o = '<a href="#output">Text output</a>\n';
                data = regexprep( data, '<pre class="codeoutput">\n?', '\n<a id="output"></a><pre class="codeoutput">\n' );
            else
                control_o = 'Text output\n';
            end
            if ~isempty( regexp( data, '</pre>\s*<img', 'once' ) ),
                control_p = '<a href="#plots">Plots</a>\n';
                data = regexprep( data, '</pre>\s*<img', '</pre>\n<a id="plots"></a><div id="plotoutput">\n<img' );
                data = regexprep( data, '</div>\s*</body>', '</div></div></body>' );
            else
                control_p = 'Plots\n';
            end
            control = sprintf( 'Jump to:&nbsp;&nbsp;&nbsp;&nbsp;\n<a href="#source">Source code</a>&nbsp;&nbsp;&nbsp;&nbsp;\n%s&nbsp;&nbsp;&nbsp;&nbsp;\n%s&nbsp;&nbsp;&nbsp;&nbsp;<a href="%sindex.html">Library index</a>', control_o, control_p, backpath );
            data = regexprep( data, '<!--control-->', control );
            data = regexprep( data, '<html>', '<html>\n' );
            data = regexprep( data, '(<div|<pre|</div>|<body>|</body>|</html>)', '\n$1' );
            data = regexprep( data, '^\s*<!DOCTYPE.*?>','<!DOCTYPE HTML>' );
            data = regexprep( data, '<meta http-equiv.*?>', '<meta charset="UTF-8">' );
            data = regexprep( data, '\s*((v|h)space=\S*)', '' );
            data = regexprep( data, '\s*(<meta|<title)','\n$1' );
            data = regexprep( data, '/>', '>' );
            f_out = fopen( [ 'html', filesep, name, '.html' ], 'w' );
            fwrite( f_out, data );
            fclose( f_out );
            delete( [ 'html', filesep, name, '_.html' ] );
            fprintf( 1, ' done.\n' );
        end
    catch
        err = lasterror;
        fprintf( 1, ' aborted.\n' );
        cd( odir );
        fprintf( 1, '===> ERROR: %s\n', err.message );
        success = false;
    end
    if runonly,
        disp( out___ );
    else
        delete( [ name, '_.m' ] );
    end
    cd( odir );
    if ~success && ~runonly && exist( hdir, 'dir' ),
        cd( hdir );
        df = dir( hfile );
        if length( df ) == 1,
            delete( hfile );
        end
        cd( odir );
    end
    close all
else
    fprintf( 1, 'up to date.\n' );
end

function title = generate_doc( name, prefix, force )

if length( name ) < 5 || ~strcmp( name(end-3:end), '.tex' ),
    error( 'Not an valid TeX file.' );
else
    fprintf( 1, '%s%s: ', prefix, name );
end

dd = dir( name );
ndate = date_convert( dd.date );
[ fidr, message ] = fopen( name, 'r' );
if fidr < 0,
    error( 'Cannot open the source file\n   %s', message );
end
title = '';
while ~feof( fidr ),
    temp = strtrim( fgetl( fidr ) );
    kndx = strfind( temp, '\title{' );
    if isempty( kndx ), continue; end
    knd2 = strfind( temp(kndx(1):end), '}' );
    if isempty( knd2 ), continue; end
    title = strtrim(temp(kndx(1)+7:kndx(1)+kndx(2)-2));
    break;
end
pdffile = [ name(1:end-3), 'pdf' ];
hdate = 0;
df = dir( pdffile );
if length( df ) == 1,
    hdate = date_convert( df.date );
end
if force || hdate < ndate,
    if hdate == 0,
        fprintf( 1, 'creating %s:', hfile );
    else
        fprintf( 1, 'updating %s:', hfile );
    end
    name2 = name(1:end-4);
    eval( sprintf( '!latex %s', name2 ) );
    eval( sprintf( '!latex %s', name2 ) );
    eval( sprintf( '!bibtex %s', name2 ) );
    eval( sprintf( '!latex %s', name2 ) );
    eval( sprintf( '!latex %s', name2 ) );
    eval( sprintf( '!latex %s', name2 ) );
    eval( sprintf( '!dvips %s', name2 ) );
    eval( sprintf( '!ps2pdf %s.ps', name2 ) );
end

function dnum = date_convert( dstr )
persistent mstrs
if isempty( mstrs ),
    mstrs = { 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec' };
end
% DD-MMM-YY HH:MM:SS
S = sscanf( dstr, '%d-%3s-%d %d:%d:%d' );
S = [ S(5), find(strcmp(char(S(2:4)'),mstrs)), S(1), S(6), S(7), S(8) ];
dnum = S(6) + 100 * ( S(5) + 100 * ( S(4) + 100 * ( S(3) + 100 * ( S(2) + 100 * S(1) ) ) ) );

function compare_and_replace( prefix, oldname )

names = { oldname, [ oldname, '.new' ] };
fprintf( 1, '%s%s ... ', prefix, oldname );
fids = [];
c = {};
for k = 1 : 2,
    [ fids(k), message ] = fopen( names{k}, 'r' );
    if fids(k) < 0 && ~isempty( dir( names{k} ) ),
        error( 'Cannot open file %s for reading:\n   %s', names{k}, message );
    end
    c{k} = fread( fids(k), Inf, 'uint8' );
    fclose( fids(k) );
end
if isempty( c{2} ),
    if fids(k) >= 0,
        fprintf( 1, ' removed.\n' );
        delete( oldname );
    end
    delete( names{2} );
elseif length( c{1} ) ~= length( c{2} ) || any( c{1} ~= c{2} ),
    [ success, message ] = movefile( names{2}, names{1}, 'f' );
    if ~success,
        error( 'Cannot move %s into place\n   %s', names{2}, message );
        delete( names{2} )
    end
    if ~isempty( c{1} ),
        fprintf( 1, ' updated.\n' );
    else
        fprintf( 1, ' created.\n' );
    end
else
    delete( names{2} )
    fprintf( 1, ' up to date.\n' );
end

function run_clean_octave( name )
feval( name );

function out___ = run_clean( name )
out___ = evalc( name );
