function L = test_Lipschitz( f, N , nRep, Ltest, lb, ub, scale)
% TEST_LIPSCHITZ Checks that the TFOCS smooth function object "f"
%   has a Lipschitz continuous gradient.
% L = TEST_LIPSCHITZ( f, N )
%   outputs an estimated Lipschitz constant
% L = TEST_LIPSCHITZ( f, N, nRep )
%   outputs an estimated Lipschitz constant based on nRep points
%
% L = TEST_LIPSCHITZ( f, N, nRep, L_guess )
%   tests is the Lipschitz constant is certainly larger than L_guess
%
% ... = TEST_LIPSCHITZ(  ..., lb, ub, scale )
%   controls how input points are sampled. They are sampled
%   as scale*randn(), and then thresholded to be bigger (element-wise)
%   than the lowerbound "lb", and less than the upperbound "ub"
%   (leave lb and/or ub at the empty matrix [] to set them
%    to -Inf and +Inf, resp.)
%
% Stephen Becker, 4/3/2017

if numel(N) == 1
    N(2) = 1;
end
if nargin < 3 || isempty( nRep )
    nRep    = 10;
end
if nargin < 4 || isempty(Ltest)
    Ltest   = Inf;
end
if nargin < 5 || isempty(lb), lb = -Inf; end
if nargin < 6 || isempty(ub), ub = Inf; end
if nargin < 7 || isempty(scale), scale = 10; end

% Generate a lot of points
X   = cell( nRep, 1 );
F   = zeros( nRep, 1 );
gra = cell( nRep, 1 );
for rep = 1:nRep
    x               = max(  min(scale*randn(N),ub), lb );
    X{rep}          = x;
    [F(rep),gra{rep}]    = f( x );
    
end
    
if nRep <= 20
    % find all pairs
    list    = nchoosek( 1:nRep, 2 );
else
    % there are a lot, so just pick some of them
    list    = zeros( 400, 2 );
    for i = 1:size(list,1)
        list(i,:)   = randsample( nRep, 2 )';
    end
end

L   = 0;
for k = 1:size(list,2)
    i   = list(k,1);
    j   = list(k,2);
    
    xg  = dot( X{i} - X{j}, gra{i} - gra{j} );
    dg  = norm( gra{i} - gra{j} );
    dx  = norm( X{i} - X{j} );
    
    % need || gradient_i - gradient_j || <= L * || x_i - x_j ||
    L   = max( L, dg/dx );
    if L > Ltest, fprintf(2,'Found L > Ltest from criteria 1\n'); return; end
    
    % need dot( gradient_i - gradient_j, x_i - x_j ) <= L || x_i - x_j ||^2
    L   = max( L,xg/(dx^2) );
    if L > Ltest, fprintf(2,'Found L > Ltest from criteria 2\n'); return; end
    
    % need ||gradient_i - gradient_j||^2 <= L*dot( gradient_i - gradient_j, x_i - x_j )
    L   = max( L, dg^2/xg );
    if L > Ltest, fprintf(2,'Found L > Ltest from criteria 3\n'); return; end
    
    % need f(i) <= f(j) + dot( gradient_j, x_i-x_j) + L/2||x_i-x_j||^2
    L   = max( L, ( F(i)-F(j) - dot( gra{j}, X{i} - X{j} ) )/( dx^2/2 ) );
    if L > Ltest, fprintf(2,'Found L > Ltest from criteria 4\n'); return; end
end


% TFOCS v1.3 by Stephen Becker, Emmanuel Candes, and Michael Grant.
% Copyright 2017 California Institute of Technology and CVX Research.
% See the file LICENSE for full license information.
