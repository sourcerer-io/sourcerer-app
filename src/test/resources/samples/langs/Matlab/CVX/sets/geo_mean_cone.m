function [ cvx_optpnt, mode ] = geo_mean_cone( sx, dim, w, mode )

%GEO_MEAN_CONE    Cones involving the geometric mean.
%   GEO_MEAN_CONE(N), where N is a positive integer, creates a column vector
%   variable X of length N and a scalar variable Y, and constrains them to
%   satisfy GEO_MEAN(X) >= Y and X >= 0. That is, given the declaration
%       variables x(n) y
%   the constraint
%       {x,y} == geo_mean_cone(n)
%   is equivalent to
%       geo_mean(x) >= y
%   CVX uses the GEO_MEAN_CONE to implement the GEO_MEAN function and a
%   variety of others, including POW_POS, POW_P, POW_ABS, and NORM. For
%   clarity, users should prefer these functions instead of using this cone
%   directly.
%
%   GEO_MEAN_CONE(SY,DIM), where SY is a valid size vector and DIM is a
%   positive integer, creates an array variable of size SY and and an array
%   variable of size SX (see below) and applies the geometric mean
%   constraint along dimension DIM. That is, given the declarations
%       sy = sx; sy(min(dim,length(sx)+1))=1;
%       variables x(sx) y(sy)
%   the constraint
%       {x,y} == geo_mean_cone(sx,dim)
%   is equivalent to
%       geo_mean(x,dim) >= y
%   Again, the inequality form is preferred, but CVX uses the set form
%   internally. DIM is optional; if it is omitted or empty, the first
%   non-singleton dimension is used.
%
%   GEO_MEAN_CONE(SX,DIM,W), where W is a vector of nonnegative numbers,
%   replaces the standard geometric mean with a weighted geometric mean
%       geo_mean(x,dim,w) >= y
%   The standard geometric mean is equivalent to W=ones(SX(DIM),1). Due to
%   the way CVX implements weighted geometric means, it rounds the elements
%   of W to the "nearest" rationals according to the RAT function.
%
%   GEO_MEAN_CONE(SX,MODE),
%   GEO_MEAN_CONE(SX,DIM,MODE), or
%   GEO_MEAN_CONE(SX,DIM,W,MODE), where MODE is a string, generates a number
%   of alternative cones:
%       MODE = 'HYPO': geo_mean(x) >= y
%       MODE = 'POS' : geo_mean(x) >= y, y >= 0
%       MODE = 'ABS' : geo_mean(x) >= abs(y) 
%       MODE = 'CABS': geo_mean(x) >= abs(y), y complex
%       MODE = 'FUNC': select 'POS' or 'ABS', depending on which one is
%          is cheaper to implement. This is useful when y can be guaranteed
%          to be nonnegative in some other way; say, through an external
%          constraint or a maximizing objective. The mode actually used
%          will be returned as a second output argument.
%       MODE = '' is the same as MODE = 'HYPO'. GEO_MEAN_CONE is insensitive
%       to case; e.g., 'pos' is equivalent to 'POS'.
%
%   Disciplined convex programming information:
%       GEO_MEAN_CONE is a CVX set specification. See the user guide for
%       details on how to use sets. However, it is strongly recommended
%       that users take advantage of this set by calling the functions that
%       utilize it; i.e., GEO_MEAN, POW_POS, POW_ABS, POW_P, NORM, etc.
%       Doing so will produce models that are simpler to understand.

%
% Check size vector
%

[ temp, sx ] = cvx_check_dimlist( sx, true );
if ~temp,
    error( 'First argument must be a dimension vector.' );
end

%
% Check dimension
%

if nargin < 4,
    mode = '';
end
if nargin == 2 && ischar( dim ),
    mode = dim;
    dim = cvx_default_dimension( sx );
elseif nargin < 2 || isempty( dim ),
    dim = cvx_default_dimension( sx );
elseif ~cvx_check_dimension( dim, true ),
    error( 'Second argument must be a nonnegative integer.' );
end
sy = sx;
nd = length( sx );
if dim <= 0 || dim > nd || sx( dim ) == 1,
    nx  = 1;
    dim = 0;
else
    nx = sx( dim );
    sy( dim ) = 1;
end

%
% Check weight vector
%

if nargin == 3 && ischar( w ),
    mode = w;
    w = [];
elseif nargin < 3 || isempty( w ),
    w = [];
elseif numel( w ) ~= length( w ) || ~isnumeric( w ) || ~isreal( w ) || any( w < 0 ),
    error( 'Third argument must be a vector of nonnegative real numbers.' );
elseif length( w ) ~= nx,
    error( 'Third argument must be a vector of length %d', nx );
elseif nx ~= 0 && ~any( w ),
    error( 'At least one of the weights must be nonzero.' );
end
if ~isempty( w ) && any( w ~= floor( w ) ),
    [ nn, dd ] = rat( w );
    dmax = dd(1);
    for k = 2 : length(dd), dmax = lcm(dmax,dd(k)); end
    w = nn .* ( dmax ./ dd );
end

%
% Check mode string
%

if isempty( mode ),
    mode = 'hypo';
elseif ~ischar( mode ) || size( mode, 1 ) > 1,
    error( 'Mode must be a string.' );
else
    lmode = lower(mode);
    if ~any( strcmp( lmode, { 'hypo', 'pos', 'abs', 'cabs', 'func' } ) ),
        error( [ 'Invalid mode string: ', mode ] );
    end
    mode = lmode;
end

%
% Quick exit for empty arrays and degenerate cases
%

if any( sx == 0 ),
    cvx_begin set
        variables x(sx) y(sy)
    cvx_end
    return
elseif nx == 1,
    cvx_begin set
        variable x(sx)
        x >= 0; %#ok
        switch mode,
            case { 'hypo', 'func' },
                variable y(sy)
                x >= y; %#ok
            case 'pos',
                variable y(sy)
                x >= y;  %#ok
                y >= 0; %#ok
            case 'abs',  
                variable y(sy)
                x >= abs( y ); %#ok
            case 'cabs',
                variable y(sy) complex
                x >= abs( y ); %#ok
        end
    cvx_end
    return
end

%
% Construct the cone.
% --- For nx == 2, the geo_mean the following equivalency
%        sqrt( x(1) * x(2) ) >= | y |, x >= 0 <--> [x(1),y;y,x(2)] psd
% --- For nx == 2^k, we can recursively apply this k times. For example,
%     for nx = 4, we have
%        ( x(1) * x(2) * x(3) * x(4) )^(1/4) >= | y |, x >= 0
%     is equivalent to
%        sqrt( w(1) * w(2) ) >= |y|,      w(1),w(2) >= 0
%        sqrt( x(1) * x(2) ) >= | w(1) |, x(1),x(2) >= 0
%        sqrt( x(3) * x(4) ) >= | w(2) |, x(3),x(4) >= 0
%     which can be represented by 3 2x2 LMIs.
% --- For other values of nx, we note that
%        prod( x )^(1/nx) >= y, x >= 0, y >= 0
%     is equivalent to
%        prod( [ x ; y * ones(ny,1) ] )^(1/(nx+ny)) >= y
%     so by adding extra y's to the left-hand side, we can use the same
%     recursion for lengths that are not powers of two.
% --- Note that the power-of-two cone allows y to be negative, while the 
%     non-power-of-two cone does not. Therefore, for consistency, we have
%     to modify one cone or the other appropriately. For instance, to
%     recover the absolute value behavior in the latter case, we must
%     actually construct the cone
%        prod( x )^(1/nx) >= z >= abs(y), x >= 0, z >= 0
% --- For integer-weighted geometric means, we must effectively replicate
%     each x(i) w(i) times. However, because sqrt( x(i) * x(i) ) = x(i),
%     we can prune away most of the duplicated values very cheaply. The
%     number of non-trivial appearances of x(i) will be reduced from w(i)
%     to at most ceil(log2(w(i))), or more precisely the number of 1's in 
%     a binary expansion of w(i). In fact, the number might be lower than
%     that thanks to savings achieved by grouping terms with common bit
%     patterns in their w(i) values.
%

%
% Construct the map
%

if isempty( w ) || ~any( diff( w ) ),
    wbasic = true;
    wsum = nx;
    w = ones( 1, nx );
else
    w = w(:)';
    for k = factor(min(w(w~=0))),
        if all( rem( w, k ) == 0 ), w = w / k; end
    end
    wsum = sum( w );
    wbasic = false;
end
worig = w;
nq = nextpow2(wsum);
nw = pow2(nq);
ndxs = 1 : nx;
if nw > wsum,
    ndxs(end+1) = 0;
    w(end+1) = nw - wsum;
end
%
% Look for candidates with common factors that can be
% extracted to save LMI blocks: e.g.,
%    ( x1^3 x2^2 x2^3 )^(1/8) =
%       = ((sqrt(x1 x3))^(1/6) x2^2)^(1/8)
%
n3 = nx;
map = [];
if ~wbasic,
    [ ff, ee ] = log2( w ); %#ok
    ndx1 = find( ff ~= 0.5 & ff ~= 0 );
    while length( ndx1 ) > 1,
        % Build cross matrix
        nv = length( ndx1 );
        ww = w( ndx1 );
        ww = ones( nv, 1 ) * ww;
        [ wi, wj, ww ] = find( bitand( tril(ww,-1)', triu(ww,1) ) );
        [ ff, ee ] = log2( ww ); 
        ndx2 = find( ff ~= 0.5 );
        if isempty( ndx2 ), break; end
        % Greedy: select the largest overlap
        ee = ee(ndx2);
        [ wc_t, wnm ] = max( sum(dec2bin(ww(ndx2))-'0',2)+(1-ee/(max(ee)+1)) ); %#ok
        % Construct a 2-element geo_mean
        wi_t     = ndx1(wi(ndx2(wnm)));
        wj_t     = ndx1(wj(ndx2(wnm)));
        n3       = n3 + 1;
        ndxs     = [ ndxs, n3 ]; %#ok
        map      = [ map, [ ndxs(wi_t) ; ndxs(wj_t) ; n3 ] ]; %#ok
        % Update the weights
        wt       = bitand( w(wi_t), w(wj_t) );
        w(end+1) = 2 * wt; %#ok
        try
            wt       = bitcmp( wt, nq );
            w(wi_t)  = bitand( w(wi_t), wt );
            w(wj_t)  = bitand( w(wj_t), wt );
        catch
            wt       = bitcmp( uint64(wt) );
            w(wi_t)  = double( bitand( uint64(w(wi_t)), wt ) );
            w(wj_t)  = double( bitand( uint64(w(wj_t)), wt ) );
        end
        % Update the count
        ndx1 = [ ndx1, length(ndxs) ]; %#ok
        [ ff, ee ] = log2( w(ndx1) ); %#ok
        ndx1 = ndx1( ff ~= 0.5 & ff ~= 0 );
    end
end

%
% Now do standard left-to-right combining
%    x1^3 x2^2 x3^3 = x1 x1 x1 x2 x2 x3 x3 x3
%       = (x1 x1)(x1 x2)(x2 x3)(x3 x3)
%
for k = 1 : nq,
    tt  = rem( w, 2 ) ~= 0;
    w   = floor( 0.5 * w );
    n12 = ndxs( tt );
    ntt = 0.5 * length( n12 );
    if ntt >= 1,
        n3    = n3(end) + 1 : n3(end) + ntt;
        map   = [ map, [ reshape( n12, 2, ntt ) ; n3 ] ]; %#ok
        ndxs  = [ ndxs, n3 ]; %#ok
        w     = [ w, ones( 1, ntt ) ]; %#ok
    end
end
if ~isempty( map ),
    map(map==0) = map(end);
else
    map = zeros(3,0);
end

%
% Build the cone
%

nv    = prod( sy );
nm    = size(map,2);
mused = nnz( map == nm + nx ) > 1;
cvx_begin set
    variable x( nx, nv );
    if isequal( mode, 'cabs' ),
        variable y( 1, nv ) complex;
    else
        variable y( 1, nv );
    end
    variable xw( nm-1, nv );
    cone = [];
    xa = [];
    switch mode,
        case 'func',
            if mused,
                mode = 'pos';
            else
                mode = 'abs';
            end
        case 'hypo',
            variable xa( 1, nv );
            y <= xa; %#ok
        case 'pos',
            if ~mused,
                y >= 0; %#ok
            end
        case 'abs',
            if mused,
                variable xa( 1, nv );
                abs( y ) <= xa; %#ok
            end
        case 'cabs',
            if mused,
                variable xa( 1, nv );
                abs( y ) <= xa; %#ok
            else
                cone = hermitian_semidefinite( [2,2,1,nv] );
            end
    end
    if isempty( xa ),
        xa = y;
    end
    if isempty( cone ),
        cone = semidefinite( [2,2,nm,nv] );
    elseif nm > 1,
        cone = cat( 3, semidefinite( [2,2,nm-1,nv] ), cone );
    end
    xt = [ x ; xw ; xa ]; %#ok
    xt( map(1,:), : ) == reshape( cone(1,1,:,:), [nm,nv] ); %#ok
    xt( map(2,:), : ) == reshape( cone(2,2,:,:), [nm,nv] ); %#ok
    xt( map(3,:), : ) == reshape( cone(2,1,:,:), [nm,nv] ); %#ok
    tt = worig == 0;
    if any( tt ),
        x( tt, : ) >= 0; %#ok
    end
cvx_end

%
% Permute and reshape as needed
%

nleft = prod( sx(1:dim-1) );
nright = prod( sx(dim+1:end) );
if nleft > 1,
    x = reshape( x, [ nx, nleft, nright ] );
    y = reshape( y, [ 1,  nleft, nright ] );
    x = permute( x, [ 2, 1, 3 ] );
    y = permute( y, [ 2, 1, 3 ] );
end
x = reshape( x, sx );
y = reshape( y, sy );
cvx_optpnt = cvxtuple( struct( 'x', x, 'y', y ) );

% Copyright 2005-2016 CVX Research, Inc.
% See the file LICENSE.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.
