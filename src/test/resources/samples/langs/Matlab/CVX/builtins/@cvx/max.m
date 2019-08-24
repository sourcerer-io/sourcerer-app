function z = max( x, y, dim )

%   Disciplined convex/geometric programming information:
%       MAX is convex, log-log-convex, and nondecreasing in its first 
%       two arguments. Thus when used in disciplined convex programs, 
%       both arguments must be convex (or affine). In disciplined 
%       geometric programs, both arguments must be log-convex/affine.

persistent remap remap_1 remap_2 remap_3
narginchk(1,3);
if nargin == 2,

    %
    % max( X, Y )
    %

    sx = size( x );
    sy = size( y );
    xs = all( sx == 1 );
    ys = all( sy == 1 );
    if xs,
        sz = sy;
    elseif ys || isequal( sx, sy ),
        sz = sx;
    else
        error( 'Array dimensions must match.' );
    end

    %
    % Determine the computation methods
    %


    if isempty( remap ),
        remap1 = cvx_remap( 'real' );
        remap1 = remap1' * remap1;
        remap2 = cvx_remap( 'log-valid' )' * cvx_remap( 'nonpositive' );
        remap3 = remap2';
        remap4 = cvx_remap( 'log-convex', 'real' );
        remap4 = remap4' * remap4;
        remap5 = cvx_remap( 'convex' );
        remap5 = remap5' * remap5;
        remap   = remap1 + ~remap1 .* ...
            ( 2 * remap2 + 3 * remap3 + ~( remap2 | remap3 ) .* ...
            ( 4 * remap4 + ~remap4 .* ( 5 * remap5 ) ) );
    end
    vx = cvx_classify( x );
    vy = cvx_classify( y );
    vr = remap( vx + size( remap, 1 ) * ( vy - 1 ) );
    vu = sort( vr(:) );
    vu = vu([true;diff(vu)~=0]);
    nv = length( vu );

    %
    % The cvx multi-objective problem
    %

    xt = x;
    yt = y;
    if nv ~= 1,
        z = cvx( sz, [] );
    end
    for k = 1 : nv,

        %
        % Select the category of expression to compute
        %

        if nv ~= 1,
            t = vr == vu( k );
            if ~xs,
                xt = cvx_subsref( x, t );
                sz = size( xt ); %#ok
            end
            if ~ys,
                yt = cvx_subsref( y, t );
                sz = size( yt ); %#ok
            end
        end

        %
        % Apply the appropriate computation
        %

        switch vu( k ),
        case 0,
            % Invalid
            error( 'Disciplined convex programming error:\n    Cannot perform the operation max( {%s}, {%s} )', cvx_class( xt, false, true ), cvx_class( yt, false, true ) );
        case 1,
            % constant
            cvx_optval = cvx( max( cvx_constant( xt ), cvx_constant( yt ) ) );
        case 2,
            % max( log-valid, nonpositive ) (no-op)
            cvx_optval = xt;
        case 3,
            % max( nonpositive, log-valid ) (no-op)
            cvx_optval = yt;
        case 4,
            % posy
            zt = [];
            cvx_begin gp
                epigraph variable zt( sz );
                xt <= zt; %#ok
                yt <= zt; %#ok
            cvx_end
        case 5,
            % non-posy
            zt = [];
            cvx_begin
                epigraph variable zt( sz );
                xt <= zt; %#ok
                yt <= zt; %#ok
            cvx_end
        otherwise,
            error( 'Shouldn''t be here.' );
        end

        %
        % Store the results
        %

        if nv == 1,
            z = cvx_optval;
        else
            z = cvx_subsasgn( z, t, cvx_optval );
        end

    end

else

    %
    % max( X, [], dim )
    %

    if nargin > 1 && ~isempty( y ),
        error( 'max with two matrices to compare and a working dimension is not supported.' );
    end

	%
	% Size check
	%

	try
		ox = x;
		if nargin < 3, dim = []; end
		[ x, sx, sy, zx, zy, nx, nv, perm ] = cvx_reduce_size( x, dim ); %#ok
	catch exc
	    error( exc.message );
	end
	
	%
	% Quick exit for empty array
	%
	
	if isempty( x ),
		z = zeros( zx );
		return
	end
	
    %
    % Type check
    %

    if isempty( remap_3 ),
        remap_1 = cvx_remap( 'real' );
        remap_2 = cvx_remap( 'log-convex', 'real' );
        remap_3 = cvx_remap( 'convex' );
    end
    vx = cvx_reshape( cvx_classify( x ), sx );
    t1 = all( reshape( remap_1( vx ), sx ) );
    t2 = all( reshape( remap_2( vx ), sx ) );
    t3 = all( reshape( remap_3( vx ), sx ) );
    t3 = t3 & ~( t1 | t2 );
    t2 = t2 & ~t1;
    ta = t1 + ( 2 * t2 + 3 * t3 ) .* ~t1;
    nu = sort( ta(:) );
    nu = nu([true;diff(nu)~=0]);
    nk = length( nu );

    %
    % Quick exit for size 1
    %

    if nx == 1 && all( nu ),
        z = ox;
        return
    end

    %
    % Perform the computations
    %

    if nk ~= 1,
        z = cvx( [ 1, nv ], [] );
    end
    for k = 1 : nk,

        if nk == 1,
            xt = x;
        else
            tt = ta == nu( k );
            xt = cvx_subsref( x, ':', tt );
            nv = nnz( tt ); %#ok
        end

        switch nu( k ),
            case 0,
                error( 'Disciplined convex programming error:\n   Invalid computation: max( {%s} )', cvx_class( xt, false, true ) );
            case 1,
                cvx_optval = max( cvx_constant( xt ), [], 1 );
            case 2,
	            zt = [];
                cvx_begin gp
                    epigraph variable zt( 1, nv )
                    xt <= ones(nx,1) * zt; %#ok
                cvx_end
            case 3,
	            zt = [];
                cvx_begin
                    epigraph variable zt( 1, nv )
                    xt <= ones(nx,1) * zt; %#ok
                cvx_end
            otherwise,
                error( 'Shouldn''t be here.' );
        end

        if nk == 1,
            z = cvx_optval;
        else
            z = cvx_subsasgn( z, tt, cvx_optval );
        end

    end

    %
    % Reverse the reshaping and permutation steps
    %

    z = reshape( z, sy );
    if ~isempty( perm ),
        z = ipermute( z, perm );
    end

end

% Copyright 2005-2016 CVX Research, Inc.
% See the file LICENSE.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.
