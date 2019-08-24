function shim = cvx_sedumi( shim )

% CVX_SOLVER_SHIM	SeDuMi interface for CVX.
%   This procedure returns a 'shim': a structure containing the necessary
%   information CVX needs to use this solver in its modeling framework.

global cvx___
if ~isempty( shim.solve ),
    return
end
if isempty( shim.name ),
    fname = 'sedumi.m';
    fs = cvx___.fs;
    ps = cvx___.ps;
    int_path = [ cvx___.where, fs ];
    int_plen = length( int_path );
    shim.name = 'SeDuMi';
    shim.dualize = true;
    flen = length(fname);
    fpaths = { [ int_path, 'sedumi', fs, fname ] };
    fpaths = [ fpaths ; which( fname, '-all' ) ];
    old_dir = pwd;
    oshim = shim;
    shim = [];
    for k = 1 : length(fpaths),
        fpath = fpaths{k};
        if ~exist( fpath, 'file' ) || any( strcmp( fpath, fpaths(1:k-1) ) ),
            continue
        end
        new_dir = fpath(1:end-flen-1);
        cd( new_dir );
        tshim = oshim;
        tshim.fullpath = fpath;
        tshim.version = 'unknown';
        is_internal = strncmp( new_dir, int_path, int_plen );
        if is_internal,
            tshim.location = [ '{cvx}', new_dir(int_plen:end) ];
        else
            tshim.location = new_dir;
        end
        try
            fid = fopen(fname);
            otp = fread(fid,Inf,'uint8=>char')';
            fclose(fid);
        catch errmsg
            tshim.error = sprintf( 'Unexpected error:\n%s\n', errmsg.message );
        end
        if isempty( tshim.error ),
            otp = regexp( otp, 'SeDuMi \d\S+', 'match' );
            if ~isempty(otp), tshim.version = otp{end}(8:end); end
            vnum = str2double( tshim.version );
            tshim.check = @check;
            tshim.solve = @solve;
            tshim.eargs = { vnum >= 1.3 && vnum < 1.32 };
            if k ~= 2,
                tshim.path = [ new_dir, ps ];
                if ~isempty(cvx___.msub) && exist([new_dir,fs,cvx___.msub],'dir'),
                   tshim.path = [ new_dir, fs, cvx___.msub, ps, tshim.path ];
                end
            end
        end
        shim = [ shim, tshim ]; %#ok
    end
    cd( old_dir );
    if isempty( shim ),
        shim = oshim;
        shim.error = 'Could not find a SeDuMi installation.';
    end
else
    shim.check = @check;
    shim.solve = @solve;
    vnum = str2double( shim.version );
    shim.eargs = { vnum >= 1.3 && vnum < 1.32 };
end
    
function found_bad = check( nonls ) %#ok
found_bad = false;

function [ x, status, tol, iters, y, z ] = solve( At, b, c, nonls, quiet, prec, settings, nocplx )

n = length( c );
m = length( b );
K = struct( 'f', 0, 'l', 0, 'q', [], 'r', [], 's', [], 'scomplex', [], 'ycomplex', [] );
reord = struct( 'n', 0, 'r', [], 'c', [], 'v', [] );
reord = struct( 'f', reord, 'l', reord, 'a', reord, 'q', reord, 'r', reord, 's', reord, 'h', reord );
reord.f.n = n;
zinv = [];
for k = 1 : length( nonls ),
    temp = nonls( k ).indices;
    nn = size( temp, 1 );
    nv = size( temp, 2 );
    nnv = nn * nv;
    tt = nonls( k ).type;
    reord.f.n = reord.f.n - nnv;
    if strncmp( tt, 'i_', 2 ),
        error( 'SeDuMi does not support integer variables.' );
    elseif nn == 1 || isequal( tt, 'nonnegative' ),
        reord.l.r = [ reord.l.r ; temp(:) ];
        reord.l.c = [ reord.l.c ; reord.l.n + ( 1 : nnv )' ];
        reord.l.v = [ reord.l.v ; ones( nnv, 1 ) ];
        reord.l.n = reord.l.n + nnv;
    elseif isequal( tt, 'lorentz' ),
        if nn == 2,
            rr = [ temp ; temp ];
            cc = reshape( floor( 1 : 0.5 : 2 * nv + 0.5 ), 4, nv );
            vv = [1;1;-1;1]; vv = vv(:,ones(1,nv));
            reord.a.r = [ reord.a.r ; rr(:) ];
            reord.a.c = [ reord.a.c ; cc(:) + reord.a.n ];
            reord.a.v = [ reord.a.v ; vv(:) ];
            reord.a.n = reord.a.n + nnv;
            zinv = [ zinv ; temp(:) ]; %#ok
        else
            temp = temp( [ end, 1 : end - 1 ], : );
            reord.q.r = [ reord.q.r ; temp(:) ];
            reord.q.c = [ reord.q.c ; reord.q.n + ( 1 : nnv )' ];
            reord.q.v = [ reord.q.v ; ones(nnv,1) ];
            reord.q.n = reord.q.n + nnv;
            K.q = [ K.q, nn * ones( 1, nv ) ];
        end
    elseif isequal( tt, 'semidefinite' ),
        if nn == 3,
            temp = temp( [1,3,2], : );
            tempv = [sqrt(2);sqrt(2);1] * ones(1,nv);
            reord.r.r = [ reord.r.r ; temp(:) ];
            reord.r.c = [ reord.r.c ; reord.r.n + ( 1 : nnv )' ];
            reord.r.v = [ reord.r.v ; tempv(:) ];
            reord.r.n = reord.r.n + nnv;
            K.r = [ K.r, 3 * ones( 1, nv ) ];
            temp = temp(1:2,:);
            zinv = [ zinv ; temp(:) ]; %#ok
        else
            nn = 0.5 * ( sqrt( 8 * nn + 1 ) - 1 );
            str = cvx_create_structure( [ nn, nn, nv ], 'symmetric' );
            K.s = [ K.s, nn * ones( 1, nv ) ];
            [ cc, rr, vv ] = find( cvx_invert_structure( str, 'compact' ) );
            rr = temp( rr );
            reord.s.r = [ reord.s.r; rr( : ) ];
            reord.s.c = [ reord.s.c; cc( : ) + reord.s.n ];
            reord.s.v = [ reord.s.v; vv( : ) ];
            reord.s.n = reord.s.n + nn * nn * nv;
            reord.s.z = reord.s.v;
        end
    elseif isequal( tt, 'hermitian-semidefinite' ),
        if nn == 4,
            temp = temp( [1,4,2,3], : );
            tempv = [sqrt(2);sqrt(2);1;1] * ones(1,nv);
            reord.r.r = [ reord.r.r ; temp(:) ];
            reord.r.c = [ reord.r.c ; reord.r.n + ( 1 : nnv )' ];
            reord.r.v = [ reord.r.v ; tempv(:) ];
            reord.r.n = reord.r.n + nnv;
            reord.r.z = reord.r.v;
            K.r = [ K.r, 4 * ones( 1, nv ) ];
            temp = temp(1:2,:);
            zinv = [ zinv ; temp(:) ]; %#ok
        elseif nocplx,
            % SeDuMi's complex SDP support was broken with the 1.3 update. So
            % we must use the following complex-to-real SDP conversion to work
            % around it, at a modest cost of problem size.
            %   X >= 0 <==> exists [ Y1, Y2^T ; Y2, Y3 ] >= 0 s.t.
            %               Y1 + Y3 == real(X), Y2 - Y2^T == imag(X)
            nsq = nn; nn = sqrt( nn );
            str = cvx_create_structure( [ nn, nn, nv ], 'hermitian' );
            [ cc, rr, vv ] = find( cvx_invert_structure( str, 'compact' ) );
            cc = cc - 1;
            mm = floor( cc / nsq );
            cc = cc - mm * nsq;
            jj = floor( cc / nn );
            ii = cc - jj * nn + 1;
            jj = jj + 1;
            mm = mm + 1;
            vr = real( vv );
            vi = imag( vv );
            ii = [ ii + nn * ~vr ; ii + nn * ~vi ];
            jj = [ jj ; jj + nn ]; %#ok
            vv = sqrt( 0.5 ) * [ vr + vi ; vr - vi ];
            rr = [ rr ; rr ]; %#ok
            mm = [ mm ; mm ]; %#ok
            [ jj, ii ] = deal( min( ii, jj ), max( ii, jj ) );
            cc = ii + ( jj - 1 ) * ( 2 * nn ) + ( mm - 1 ) * ( 4 * nsq );
            K.s = [ K.s, 2 * nn * ones( 1, nv ) ];
            rr = temp( rr );
            reord.s.r = [ reord.s.r; rr( : ) ];
            reord.s.c = [ reord.s.c; cc( : ) + reord.s.n ];
            reord.s.v = [ reord.s.v; vv( : ) ];
            reord.s.n = reord.s.n + 4 * nsq * nv;
            reord.s.z = reord.s.v;
        else
            % SeDuMi's complex SDP support was restored in v1.33.
            K.scomplex = [ K.scomplex, length( K.s ) + ( 1 : nv ) ];
            nn = sqrt( nn );
            str = cvx_create_structure( [ nn, nn, nv ], 'hermitian' );
            K.s = [ K.s, nn * ones( 1, nv ) ];
            stri = cvx_invert_structure( str, 'compact' )';
            [ rr, cc, vv ] = find( stri );
            rr = temp( rr );
            reord.s.r = [ reord.s.r; rr( : ) ];
            reord.s.c = [ reord.s.c; cc( : ) + reord.s.n ];
            reord.s.v = [ reord.s.v; vv( : ) ];
            reord.s.n = reord.s.n + size( stri, 2 );
            reord.s.z = reord.s.v;
        end
    else
        error( 'Unsupported nonlinearity: %s', tt );
    end
end
if reord.f.n > 0,
    reord.f.r = ( 1 : n )';
    reord.f.r( [ reord.l.r ; reord.a.r ; reord.q.r ; reord.r.r ; reord.s.r ] ) = [];
    reord.f.c = ( 1 : reord.f.n )';
    reord.f.v = ones(reord.f.n,1);
end
n_d = max( m - n - reord.f.n + 1, isempty( At ) );
if n_d,
    reord.l.n = reord.l.n + n_d;
end
K.f = reord.f.n;
K.l = reord.l.n + reord.a.n;
n_out = reord.f.n;
reord.l.c = reord.l.c + n_out; n_out = n_out + reord.l.n;
reord.a.c = reord.a.c + n_out; n_out = n_out + reord.a.n;
reord.q.c = reord.q.c + n_out; n_out = n_out + reord.q.n;
reord.r.c = reord.r.c + n_out; n_out = n_out + reord.r.n;
reord.s.c = reord.s.c + n_out; n_out = n_out + reord.s.n;
reord = sparse( ...
    [ reord.f.r ; reord.l.r ; reord.a.r ; reord.q.r ; reord.r.r ; reord.s.r ], ...
    [ reord.f.c ; reord.l.c ; reord.a.c ; reord.q.c ; reord.r.c ; reord.s.c ], ...
    [ reord.f.v ; reord.l.v ; reord.a.v ; reord.q.v ; reord.r.v ; reord.s.v ], ...
    n, n_out );

At = reord' * At;
c  = reord' * c;
pars.free = K.f > 1 && nnz( K.q );
pars.eps     = prec(1);
pars.bigeps  = prec(3);
if quiet,
    pars.fid = 0;
end
add_row = isempty( At );
if add_row,
    K.f = K.f + 1;
    At = sparse( 1, 1, 1, n_out + 1, 1 );
    b = 1;
    c = [ 0 ; c ];
end
[ xx, yy, info ] = cvx_run_solver( @sedumi, At, b, c, K, pars, 'xx', 'yy', 'info', settings, 5 );
if add_row,
    xx = xx(2:end);
    yy = zeros(0,1);
    At = zeros(n_out,0);
    % b  = zeros(0,1);
    c  = c(2:end);
end
if ~isfield( info, 'r0' ) && info.pinf,
    info.r0 = 0;
    info.iter = 0;
    info.numerr = 0;
end
tol = info.r0;
iters = info.iter;
xx = full( xx );
yy = full( yy );
status = '';
if info.pinf ~= 0,
    status = 'Infeasible';
    x = NaN * ones( n, 1 );
    y = yy;
    z = - real( reord * ( At * yy ) );
    if add_row, y = zeros( 0, 1 ); end
elseif info.dinf ~= 0
    status = 'Unbounded';
    y = NaN * ones( m, 1 );
    z = NaN * ones( n, 1 );
    x = real( reord * xx );
else
    x = real( reord * xx );
    y = yy;
    z = real( reord * ( c - At * yy ) );
    if add_row, y = zeros( 0, 1 ); end
end
if ~isempty(zinv),
    z(zinv) = z(zinv) * 0.5;
end
if info.numerr == 2,
    status = 'Failed';
    if any( K.q == 2 ),
        warning( 'CVX:SeDuMi', cvx_error_format( 'This solver failure may possibly be due to a known bug in the SeDuMi solver. Try switching to SDPT3 by inserting "cvx_solver sdpt3" into your model.', ...
            [66,75], false, '' ) );
    end
else
    if isempty( status ),
        status = 'Solved';
    end
    if info.numerr == 1 && info.r0 > prec(2),
        status = [ 'Inaccurate/', status ];
    end
end

% Copyright 2005-2016 CVX Research, Inc.
% See the file LICENSE.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.
