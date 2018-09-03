function cvx_optval = logsumexp_sdp( x, dim, tol )

%LOGSUMEXP_SDP    SDP-based approximation of log(sum(exp(x))).
%   LOGSUMEXP_SDP(X) computes an approximation of the function
%   LOG(SUM(EXP(X))) using semidefinite programming techniques.
%   The approximation is chosen so that, to within the numerical
%   tolerance of the SDP solver,
%         Y <= LOGSUMEXP_SDP(X) <= Y + TOL
%   where Y = LOG(SUM(EXP(X))).
%
%   Our specific choice of a one-sided, absolute approximation has
%   two important consequences. First of all, the one-sidedness insures
%   that constraints that utilize LOGSUMEXP_SDP are conservative; that
%   is, they are tighter than if they were to use LOGSUMEXP exactly.
%   So if the approximate disciplined convex program is feasible, so
%   is the original.
%
%   Secondly, for geometric programs, the absolute tolerance TOL
%   translates to a *relative* tolerance of EXP(TOL) in a posynomial
%   constraint. That is, given a constraint
%       P(X) <= M(X)
%   where P(X) is posynomial and M(X) is monomial, the approximation
%   has the effect of enforcing a constraint
%       P(X) <= M(X)/(1+E)
%   for some unknown 0 <= E <= TOL, if TOL is sufficiently small.
%
%   If X is a matrix, LOGSUMEXP_SDP(X) will perform its computations
%   along each column of X. If X is an N-D array, LOGSUMEXP_SDP(X)
%   will perform its computations along the first dimension of size
%   other than 1. LOGSUMEXP_SDP(X,DIM) will perform its computations
%   along dimension DIM.
%
%   LOGSUMEXP_SDP(X,[],TOL) and LOGSUMEXP_SDP(X,DIM,TOL) allow you to
%   specify a different tolerance level TOL. The function will attempt
%   to select a polynomial that guarantees that
%         Y <= LOGSUMEXP_SDP(X) <= Y + TOL.
%   where Y = LOG(SUM(EXP(X))). Note that a fixed set of polynomials
%   have been hard-coded into this function. So if TOL is too small, an
%   error will result. In particular, the tightest tolerance currently
%   available is approximately TOL = 2.5E-006 * CEIL(LOG2(SIZE(X,DIM))).
%
%   Disciplined convex programming information:
%       LOGSUMEXP_SDP(X) is convex an nondecreasing in X; therefore, X
%       must be convex (or affine).

if ~isreal( x ),
    error( 'Input must be real.' );
end
sx = size( x );

if nargin < 2 || isempty( dim ),
    dim = cvx_default_dimension( sx );
elseif ~cvx_check_dimension( dim, true ),
    error( 'Second argument must be a valid dimension.' );
end

if nargin < 3 || isempty( tol ),
    tol = 0.01;
elseif ~isnumeric( tol ) || length( tol ) ~= 1 || ~isreal( tol ) || tol <= 0 || tol >= 1,
    error( 'tol must be a number between 0 and 1, exclusuve.' );
end

if length( sx ) < dim,
    sx( end + 1 : dim ) = 1;
end
nx = sx( dim );
if nx == 0,
    sx( dim ) = 1;
    cvx_optval = -Inf * ones( sx );
elseif any( sx == 0 ),
    cvx_optval = zeros( sx );
end

persistent polynomials tolerances offsets tols_lse2 xmax_lse2 poly_lse2;
if isempty( offsets ),
    tolerances = [ ...
        +1.097023849927867e-002 ...
        +1.721590099806229e-003 ...
        +2.812158802287952e-004 ...
        +4.429114094399135e-005 ...
        +7.148558948619577e-006 ...
        +1.231310346831937e-006 ...
    ];
    offsets = [ ...
        +4.587509890238436e+000 ...
        +6.416928175755245e+000 ...
        +8.229687874643302e+000 ...
        +1.008049537132034e+001 ...
        +1.191991494339686e+001 ...
        +1.369797783724949e+001 ...
    ];
    polynomials = { ...
        [+1.366158644955694e-001,+2.883850897160668e-001,+2.623847409587327e-001,+2.061297910417373e-001,+1.064845137988183e-001], ...
        [+7.816587775500264e-002,+1.772675324993043e-001,+1.751223611165395e-001,+1.868180367534688e-001,+2.061693656978195e-001,+1.350536359519012e-001,+4.140319049786734e-002], ...
        [+4.488353591809181e-002,+1.104412004313922e-001,+1.079322498484279e-001,+1.211618304290446e-001,+1.915334757023368e-001,+2.021823414978708e-001,+1.393582785497204e-001,+6.607402177632382e-002,+1.643306938125711e-002], ...
        [+2.814490873415288e-002,+7.107594785846445e-002,+6.206052968585951e-002,+6.721607718419953e-002,+1.457271383815143e-001,+1.945852689115283e-001,+1.756342044070035e-001,+1.342590824420419e-001,+8.195601028303283e-002,+3.284154259643590e-002,+6.499356237673634e-003], ...
        [+1.801637612736961e-002,+4.586559423151913e-002,+3.384999962721969e-002,+3.241317603008043e-002,+1.027247814175989e-001,+1.601733028401698e-001,+1.618047203594099e-001,+1.541310400190613e-001,+1.351534667914612e-001,+9.207809085897611e-002,+4.587132947107905e-002,+1.533534861989494e-002,+2.582945905589078e-003], ...
        [+1.120952456372942e-002,+2.878673733676522e-002,+1.745388744605725e-002,+1.257946442836477e-002,+6.862411666662194e-002,+1.212531261391436e-001,+1.280824998847647e-001,+1.379104300046541e-001,+1.513029046523293e-001,+1.356592949614772e-001,+9.740481865550699e-002,+5.653968254890129e-002,+2.486163130624700e-002,+7.270708398065873e-003,+1.061270861357674e-003], ...
    };
    tols_lse2 = [ ...
        +2.604710921123930e-003 ...
        +2.023606501605798e-003 ...
        +7.186272440111206e-004 ...
        +1.650184739680674e-004 ...
        +2.711947820394637e-005 ...
        +6.626536813461173e-006 ...
    ];
    xmax_lse2 = [ ...
        +3.016052268759351e+000 ...
        +3.147392938371973e+000 ...
        +3.646024500530143e+000 ...
        +4.380570181812147e+000 ...
        +5.293529886795310e+000 ...
        +5.988203932237162e+000 ...
    ];
    poly_lse2 = { ...
        [+8.159111798406757e-002,-2.088766265150633e-001,+2.184646092892881e-001,+1.371376204482131e+000,+1.556101674388225e+000], ...
        [+3.334630057313453e-004,-1.060375441845846e-002,+9.715435406796991e-002,-2.096639262924454e-001,+2.088580308017964e-001,+1.447390559617362e+000,+1.615947818063521e+000], ...
        [+6.785143656818839e-003,+2.461201556871129e-002,-3.880975391764840e-002,-8.177792840262915e-002,+1.971962632643551e-001,-1.977691864994194e-001,+1.556732730938031e-001,+1.731373759332839e+000,+1.849459541179112e+000], ...
        [+1.750842286021084e-002,+1.111985771776053e-002,-9.551682490920249e-002,+2.838017966662204e-002,+1.383678902923077e-001,-1.739700557712566e-001,+1.544268632772164e-001,-1.573031365076512e-001,+1.194780681395583e-001,+2.135484657435186e+000,+2.202759265472971e+000], ...
        [+2.654151273601881e-002,-1.332036618151814e-002,-1.163329680305297e-001,+1.166465460844204e-001,+8.891035020671029e-002,-1.666006712102975e-001,+1.126715728840250e-001,-1.311132963495887e-001,+1.602149050147826e-001,-1.258789281605399e-001,+6.955806786045883e-002,+2.620468791080553e+000,+2.651791472377042e+000], ...
        [+4.767691370849323e-002,-6.696121312219248e-002,-1.342731459018708e-001,+2.436059791387181e-001,+4.093723652936038e-002,-2.132048441979625e-001,+6.860071867460910e-002,-3.577798568743423e-002,+1.436202524622697e-001,-1.720098314357508e-001,+1.328392919340422e-001,-8.719393191264979e-002,+4.466662307495772e-002,+2.979073449755230e+000,+2.996611030953293e+000], ...
    };
end

%
% Determine the computation method.
%

nlevs  = ceil(log2(nx));
dectol = - nlevs * log( 1 - 2 * tolerances );
lintol = - log( 1 - nx * tolerances );
ls2tol = + nlevs * tols_lse2;
degs = [ min([find(ls2tol<=tol),Inf]), min([find(dectol<=tol),Inf]), min([find(lintol<=tol),Inf]) ];
if all( isinf( degs ) ),
    tmax = min( [ lintol(end), ls2tol(end), dectol(end) ] );
    error( 'A polynomial of required accuracy (%g) has not been supplied.\nConsider raising the tolerance to %g or greater to proceed.', tol, tmax );
end
nnx = nx;
npairs = 0;
for k = 1 : nlevs,
    npairs = npairs + floor( 0.5 * nnx );
    nnx = ceil( 0.5 * nnx );
end
cplx = ( 0.5 .* ( degs + 2 ) .* ( degs + 3 ) + [ 4, 2, 2 ] ) .* [ npairs, 2 * npairs, nx ];
[ cmin, dndx ] = min( cplx ); %#ok
use_lse2 = dndx == 1;
if use_lse2,
    xoff = xmax_lse2(degs(1));
    p = poly_lse2{degs(1)};
else
    xoff = offsets(degs(dndx));
    p = polynomials{degs(dndx)};
    if dndx == 3, npairs = 1; end
end

%
% Quick exits
%

if nx == 1,
    cvx_optval = x;
    return;
elseif any( sx == 0 ),
    sx( dim ) = 1;
    cvx_optval = -Inf * ones( sx );
    return
end

%
% Permute the matrix, if needed, so the geometric mean can be taken
% along the first dimension.
%

if dim > 1 && any( sx( 1 : dim - 1 ) > 1 ),
    perm = [ dim, 1 : dim - 1, dim + 1 : length( sx ) ];
    x = permute( x, perm );
    sx = sx( perm );
    dim = 1;
else
    perm = [];
end
nv = prod( sx ) / nx;
x = reshape( x, nx, nv );

%
% Perform the computation.
%

cvx_begin sdp separable
    epigraph variable y( 1, nv )
    if npairs > 1,
        variable xtemp( npairs - 1, nv );
        xq = reshape( [ x ; xtemp ], 2, npairs * nv );
        yq = reshape( [ xtemp ; y ], 1, npairs * nv );
    else
        xq = x;
        yq = y;
    end
    if use_lse2,
        xq = cvx_accept_convex( xq );
        variables w( 1, npairs * nv ) v( 1, npairs * nv )
        abs( [0.5,-0.5]*xq ) <= w + v; %#ok
        w <= xoff; %#ok
        v >= 0; %#ok
        poly_env( p, w / ( 0.5 * xoff ) - 1 ) + v + [0.5,0.5]*xq <= yq; %#ok
    else
        xy = xq - ones(size(xq,1),1) * yq;
        xy = max( xy, - xoff );
        xy = cvx_accept_convex( xy );
        sum( poly_env( p, xy / ( 0.5 * xoff ) + 1 ), 1 ) <= 1; %#ok
    end
cvx_end

%
% Reverse the reshaping and permutation steps
%

sx( dim ) = 1;
cvx_optval = reshape( cvx_optval, sx );
if ~isempty( perm ),
    cvx_optval = ipermute( cvx_optval, perm );
end

% Copyright 2005-2016 CVX Research, Inc. 
% See the file LICENSE.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.
