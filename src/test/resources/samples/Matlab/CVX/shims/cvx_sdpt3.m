function shim = cvx_sdpt3( shim )

% CVX_SOLVER_SHIM	SDPT3 interface for CVX.
%   This procedure returns a 'shim': a structure containing the necessary
%   information CVX needs to use this solver in its modeling framework.

global cvx___
if ~isempty( shim.solve ),
    return
end
if isempty( shim.name ),
    fname = 'sdpt3.m';
    ps = cvx___.ps;
    fs = cvx___.fs;
    int_path = [ cvx___.where, fs ];
    int_plen = length( int_path );
    shim.name = 'SDPT3';
    shim.dualize = true;
    flen = length(fname);
    fpaths = { [ int_path, 'sdpt3', fs, fname ] };
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
            otp = regexp( otp, 'SDPT3: version \d+\.\d+', 'match' );
            if ~isempty(otp), tshim.version = otp{1}(16:end); end
            if k ~= 2,
                tpath = { new_dir, [ new_dir, fs, 'Solver' ], [ new_dir, fs, 'HSDSolver' ], [ new_dir, fs, 'Solver', fs, 'Mexfun' ] };
                if ~isempty(cvx___.msub) && exist( [ tpath{end}, fs, cvx___.msub ], 'dir' ),
                    tpath{end} = [ tpath{end}, fs, cvx___.msub ];
                end
                tpath = sprintf( [ '%s', ps ], tpath{:} ) ;
                tshim.path = tpath;
            end
            tshim.check = @check;
            tshim.solve = @solve;
            tshim.eargs = {};
        end
        shim = [ shim, tshim ]; %#ok
    end
    cd( old_dir );
    if isempty( shim ),
        shim = oshim;
        shim.error = 'Could not find a SDPT3 installation.';
    end
else
    shim.check = @check;
    shim.solve = @solve;
    shim.eargs = {};
end

function found_bad = check( nonls ) %#ok
found_bad = false;

function [ x, status, tol, iters, y, z ] = solve( At, b, c, nonls, quiet, prec, settings )
[n,m] = size(At);

% SDPT3 cannot handle empty equality constraints or square systems. So
% add an extra row or column, as needed, to rectify this problem.

mzero = m == 0 | isempty( nonls ) | m == n;
if mzero,    
    n = n + 1;
    c = [ c ; 0 ];
    if m == 0,
        azero = true;
        At = sparse( n, 1, 1 );
        b  = 1;
        m  = 1;
    elseif m + 1 < n,
        azero = true;
        At(end+1,end+1) = 1;
        b(end+1) = 1;
        m = m + 1;
    else
        At(end+1,end) = 0;
        azero = false;
    end
    nonls(end+1).type = 'nonnegative';
    nonls(end).indices = n;
else
    azero = false;
end

types = { nonls.type };
indices = { nonls.indices };
found = false(1,length(types));
used = false(1,n);

blk  = cell( 0, 2 );
Avec = cell( 0, 1 );
Cvec = cell( 0, 1 );
xvec = cell( 0, 1 );
tvec = cell( 0, 1 );
if nargout > 3,
    need_z = true;
    zvec = cell( 0, 1 );
else
    need_z = false;
end

%
% Reject integer variables
%

if any( strncmp( types, 'i_', 2 ) ),
    error( 'SDTP3 does not support integer variables.' );
end

%
% Nonnegative variables preserved as-is
%

tt = find( strcmp( types, 'nonnegative' ) );
if ~isempty( tt ),
    for k = tt,
        ti = indices{k};
        indices{k} = reshape(ti,1,numel(ti));
    end
    ti = cat( 2, indices{tt} );
    ni = length(ti);
    blk {end+1,1} = 'l';
    blk {end,  2} = ni;
    Avec{end+1,1} = At(ti,:);
    Cvec{end+1,1} = c(ti);
    tvec{end+1,1} = ti;
    xvec{end+1,1} = 1;
    if need_z,
        zvec{end+1,1} = 1;
    end
    found(tt) = true;
    used(ti) = true;
end

%
% SDTP3 places the epigraph variable of an SOC { (x,y) | ||x||<=y }
% at the beginning of the vector; CVX places it at the end. So we must 
% reverse our ordering here.
%

tt = find( strcmp( types, 'lorentz' ) );
if ~isempty( tt ),
    blk{end+1,1} = 'q';
    blk{end,2}   = zeros(1,0);
    for k = tt,
        ti = indices{k};
        ti = ti([end,1:end-1],:);
        blk{end,2} = [ blk{end,2}, size(ti,1) * ones(1,size(ti,2)) ];
        indices{k} = reshape(ti,1,numel(ti));
    end
    ti = cat( 2, indices{tt} );
    Avec{end+1,1} = At(ti,:);
    Cvec{end+1,1} = c(ti);
    tvec{end+1,1} = ti;
    xvec{end+1,1} = 1;
    if need_z,
        zvec{end+1,1} = 1;
    end
    found(tt) = true;
    used(ti) = true;
end

tt = find( strcmp( types, 'semidefinite' ) | strcmp( types, 'hermitian-semidefinite' ) );
if ~isempty( tt ),
    blk{end+1,1}  = 's';
    blk{end,2}    = {};
    Avec{end+1,1} = {};
    Cvec{end+1,1} = {};
    tvec{end+1,1} = {};
    xvec{end+1,1} = {};
    if need_z,
        zvec{end+1,1} = {};
    end
    nnn = 0;
    for k = tt,
        ti = indices{k};
        [nt,nv] = size(ti);
        if types{k}(1) == 's',
            nn = 0.5*(sqrt(8*nt+1)-1);
        else
            nn = 2*sqrt(nt);
        end
        nnn = nnn + nn*nv;
    end
    for k = tt,
        ti = indices{k};
        [nt,nv] = size(ti);
        if types{k}(1) == 's',
            nn = 0.5 * ( sqrt(8*nt+1) - 1 );
            nt2 = nt;
            n2 = nn;
        else
            nn = sqrt(nt);
            n2 = 2 * nn;
            nt2 = 0.5 * n2 * ( n2 + 1 );
        end
        blk{end,2}{end+1} = n2 * ones(1,nv);
        tvec{end}{end+1} = ti(:);
        
        if types{k}(1) == 's',
            
            %
            % CVX stores symmetric matrix variables in packed lower triangle
            % form; and str_1 is the adjoint of the mapping from packed form to
            % unpacked form. That is, if x is an n(n+1)/2 by 1 vector, then
            % str_1' * x is the n x n symmetric matrix. To preserve inner
            % products we need the inverse operator as well:
            % <a,x> = <a,str_2'*str_1'*x> = <str_2*a,str_1'*x>
            %

            str_1 = cvx_create_structure( [nn,nn], 'symmetric' );
            
        else
            
            %
            % SDPT3 does not do complex SDP natively. To convert to real SDPs
            % there are two approaches;
            %   X >= 0 <==> [ real(X), -imag(X) ; imag(X), real(X) ] >= 0
            %   X >= 0 <==> exists [ Y1, Y2^T ; Y2, Y3 ] >= 0 s.t.
            %                        Y1 + Y3 == real(X), Y2 - Y2^T == imag(X)
            % For primal standard form, this second form is the best choice,
            % and what we end up using here.
            %
        
            str_1 = cvx_create_structure( [nn,nn], 'hermitian' );
            [rr,cr,vr] = find(real(str_1));
            cr = cr + floor((cr-1)/nn)*nn;
            [ri,ci,vi] = find(imag(str_1));
            ci = ci + floor((ci-1)/nn)*nn;
            str_1 = sparse( [rr;ri;ri;rr], [cr;ci+nn;ci+n2*nn;cr+nn*(n2+1)], [vr;vi;-vi;vr], nt, n2^2 );
            
        end
        str_2 = cvx_invert_structure( str_1 );
        
        %
        % SDPT3, on the other hand, stores symmetric matrix variables in
        % packed upper triangle format, with off-diagonal elements scaled 
        % by sqrt(2) to preserve inner products. The operator is unitary:
        % <str_2*a,str_1'*x> = <str_3*str_2*a,str_3*str_1'*x>
        %
        
        str_3 = sqrt(0.5) * ones(nt2,1); str_3(cumsum(1:n2)) = 1;
        str_3 = spdiags( str_3, 0, nt2, nt2 ) * cvx_s_symmetric_ut( n2, n2, true );
        Avec{end}{end+1} = reshape( ( str_3 * str_2 ) * reshape( At(ti,:), nt, nv * m ), nt2 * nv, m );
        
        %
        % SDPT3 expects C to be in the form of a symmetric matrix, so we
        % only need to do half the work.
        % <c,x> == <str_2*c,str_1'*x>
        %
        
        cc = reshape( str_2 * reshape( c(ti,:), nt, nv ), n2, n2 * nv );
        if nv > 1,
            % For multiple matrices, SDPT3 expects the blocks to be stacked
            % along the diagonal, but our calculation above stacks them into
            % a single row. A simple row offset fixes this.
            [ rr, cc, vv ] = find( cc );
            cc = sparse( rr + floor((cc-1)/n2)*n2, cc, vv, n2 * nv, n2 * nv );
        end
        Cvec{end}{end+1} = cc;
        
        %
        % SDPT3 presents X in symmetric form. We must extract the lower
        % triangle for CVX. No scaling is needed. For multiple blocks we
        % must add row offsets to handle the block diagonal form.
        %
        
        [ rr, cc, vv ] = find( str_2' );
        cc = cc + floor((cc-1)/n2)*(nnn-n2);
        if nv > 1,
            ov = ones(1,nv); sv = 0:nv-1;
            or = ones(length(rr),1);
            rr = rr(:,ov) + or*(sv*nt);
            cc = cc(:,ov) + or*(sv*(n2*(nnn+1)));
            vv = vv(:,ov);
        end
        xvec{end}{end+1} = sparse( cc, rr, vv, n2*nv*(nnn+1), nt*nv );
        if need_z,
            [ rr, cc, vv ] = find( str_1 );
            cc = cc + floor((cc-1)/n2)*(nnn-n2);
            if nv > 1,
                ov = ones(1,nv); sv = 0:nv-1;
                or = ones(length(rr),1);
                rr = rr(:,ov) + or*(sv*nt);
                cc = cc(:,ov) + or*(sv*(n2*(nnn+1)));
                vv = vv(:,ov);
            end
            zvec{end}{end+1} = sparse( cc, rr, vv, n2*nv*(nnn+1), nt*nv );
        end
        used(ti) = true;
    end
    blk{end,2} = horzcat( blk{end,2}{:} );
    Avec{end}  = vertcat( Avec{end}{:} );
    Cvec{end}  = cvx_blkdiag( Cvec{end}{:} );
    tvec{end}  = vertcat( tvec{end}{:} );
    xvec{end}  = cvx_blkdiag( xvec{end}{:} );
    xvec{end}(nnn*nnn+1:end,:) = [];
    if need_z,
        zvec{end} = cvx_blkdiag( zvec{end}{:} );
        zvec{end}(nnn*nnn+1:end,:) = [];
    end
    found(tt)  = true;
end

ti = find(~found);
if ~isempty(ti),
    types = unique( types(ti) );
    types = sprintf( ' %s', types{:} );
    error( 'One or more unsupported nonlinearities detected: %s', types );
end

ti = find(~used);
if ~isempty(ti),
    ni = numel(ti);
    ti = reshape( ti, 1, ni );
    blk {end+1,1} = 'u';
    blk {end,  2} = ni;
    Avec{end+1,1} = At(ti,:);
    Cvec{end+1,1} = c(ti);
    tvec{end+1,1} = ti;
    xvec{end+1,1} = 1;
    if need_z,
        zvec{end+1,1} = 1;
    end
    % found(tt) = true;
    % used(ti) = true;
end

%
% Call SDPT3
%

b = full(b);
OPTIONS = sqlparameters;
OPTIONS.gaptol = prec(1);
OPTIONS.printlevel = 3 * ~quiet;
warn_save = warning;
[ obj, xx, y, zz, info ] = cvx_run_solver( @sqlp, blk, Avec, Cvec, b, OPTIONS, 'obj', 'x', 'y', 'z', 'info', settings, 5 ); %#ok
warning( warn_save );
tol = max( [ info.relgap, info.pinfeas, info.dinfeas ] );
if ~quiet, disp(' '); end

%
% Interpret status codes
%

x_good = true;
y_good = true;
switch info.termcode,
    case 0, 
        status = 'Solved';
        tol = min( prec(2), tol );
    case 1,
        status = 'Infeasible';
        x_good = false;
        tol = min( info.dinfeas, prec(2) );
    case 2,
        status = 'Unbounded';
        y_good = false;
        tol = min( info.pinfeas, prec(2) );
    otherwise,
        if isnan(tol),
            tol = Inf;
            status = 'Failed';
        elseif tol > prec(3),
            status = 'Failed';
        elseif tol <= prec(2),
            status = 'Solved';
            info.termcode = 0;
        else
            status = 'Inaccurate/Solved';
            info.termcode = 0;
        end
end

% Primal point

if x_good,
    x = zeros(1,n);
    for k = 1 : length(xx),
        x(1,tvec{k}) = x(1,tvec{k}) + xx{k}(:)' * xvec{k};
    end
end
if x_good && all(isfinite(x)),
    x = full( x )';
else
    x = NaN * ones(n,1);
end
if mzero,
    x(end) = [];
end

% Lagrange multipliers

if y_good,
    y = full(y);
end
if ~y_good || ~all(isfinite(y)),
    y = NaN * ones(m,1);
end
if azero,
    y(end,:) = [];
end

% Iteration count

iters = info.iter;

% Dual cone

if need_z,
    if y_good,
        z = zeros(1,n);
        for k = 1 : length(zz),
            z(1,tvec{k}) = z(1,tvec{k}) + zz{k}(:)' * zvec{k};
        end
    end
    if y_good && all(isfinite(z)),
        z = full( z )';
    else
        z = NaN * ones(n,1);
    end
    if mzero,
        z(end) = [];
    end
end

% Copyright 2005-2016 CVX Research, Inc.
% See the file LICENSE.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.
