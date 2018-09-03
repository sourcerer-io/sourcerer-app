function varargout = test_nonsmooth( f, N, DOM )
% TEST_NONSMOOTH Runs diagnostic tests to ensure a non-smooth function conforms to TFOCS conventions
% TEST_NONSMOOTH( F )
%   tests whether the function handle F works as a tfocs non-nonsmooth
%   function object.
%
%   Requirements: 
%       f = F(X) must return the value of the function at X.
%       p = F(X,t) must return the proximity operator of F at X,
%           i.e. p = argmin_y  F(y) + 1/(2*t)||y-x||^2
%
%   For an example, see PROX_L1.M
%       
% TEST_NONSMOOTH( F, N )
%    specifies the size of the domain space.  If N is a scalar,
%    then the domain space is the set of  N x 1 vectors.
%    If N is a matrix of the form [n1, n2], the the domain
%    space is the set of n1 x n2 matrices.
%
% TEST_NONSMOOTH( ..., DOM )
%    specifies the domain of F.  DOM can be of the form [a,b]
%    which signifies the 1D set (a,b).
%
% OK = TEST_NONSMOTH(...)
%    returns "true" if all tests are passed, and "false" otherwise.
%
% Example:
%   test_nonsmooth( prox_l1 )
%
% See also private/tfocs_prox, prox_l1

OK = false;
PLOT = true;

error(nargchk(1,3,nargin));

if ~isa(f,'function_handle')
    fail('TFOCS nonsmooth function must be a FUNCTION HANDLE');
    return; 
end
fprintf('== Testing the nonnonsmooth function %s ==\n', func2str(f) );

if nargin < 2 || isempty(N),   N = 10;          end
if nargin < 3 || isempty(DOM), DOM = [-1,1];    end

a = DOM(1); b = DOM(2);

x = (a+b)/2;
fprintf('Testing scalar inputs... \n');
try 
    vi = f(x);
catch
    fail('TFOCS nonsmooth function failed to return a function value');
    return;
end
if isinf(vi)
    fail('TFOCS nonsmooth function tester: default domain is invalid. Please specify valid domain');
    return;
end
fprintf('\t\t\t\t...passed. \n');

% Now, also ask for the prox
fprintf('Testing proximity operator output... \n');
t = 1;
try 
    [vi,gi] = f(x,t);
catch
    fail('TFOCS nonsmooth function failed to compute a valid proximity operator');
    return;
end
fprintf('\t\t\t\t...passed. \n');


% find a reasonable value of t:
x = a + .9*(b-a);
[vi,gi] = f(x,t);
cntr = 0;
% This is only good for proximity functions: for projections,
%   the value of "t" has no effect:
if strfind( func2str(f), 'proj' )
    disp('Looks like this is a projection: this test may not work correctly.');
else
    disp('Looks like this is a proximity operator');
    while norm(gi - x )/norm(x) > .8 && cntr < 20
        t = t/2;
        cntr = cntr + 1;
        [vi,gi] = f(x,t);
    end
end
% for t = 0, we have gi = x
% for t = Inf, gi is independent of x (i.e. gi = argmin_x f(x),
%       which, for f(x) = ||x||, is gi = 0 ).



% Now, try a vector
if isscalar(N)
    x = repmat(x,N,1);
else
    x = repmat(x,N(1),N(2));
    % if a > 0, assume we want a PSD matrix:
    if a >= 0
        x = ones(N(1),N(2)) + eye(N(1),N(2) );
    end
end
fprintf('Testing vector inputs... \n');
try 
    vi = f(x);
catch
    fail('TFOCS nonsmooth function failed to compute f when supplied a vector input');
    return;
end
try 
    [vi,gi] = f(x,t);
catch
    fail('TFOCS nonsmooth function failed to compute prox_f when supplied a vector input');
    return;
end
if ~isscalar(vi)
    fail('TFOCS nonsmooth function value must be a scalar');
    return;
end
if ~all( size(gi) == size(x) )
    fail('TFOCS nonsmooth proximity function value must be same size as input');
    return;
end
fprintf('\t\t\t\t...passed. \n');

% gi = prox_{f,t}(x)
% let's verify that gi is actually a minimizer, by
% plotting the values for a few nearby points
s = min(t,.9*x(1,1) );
x = x + .1/norm(x,Inf)*randn(size(x));
[vi,gi] = f(x,s);
objective = @(y) f(y) + 1/(2*s)*norm(y-x,'fro')^2;
fprintf('Verifying the validity of the proximity calculation...\n');
objGi = objective(gi);
fprintf('\tprox(x) has objective value: %.3e\n', objGi );
sc = 1/norm(gi,'inf');
OK_objective = true;
for t = 1:20
    randPt = gi + .01*sc*randn(size(gi));
    obj = objective(randPt);
    fprintf('\tRandom pt #%2d has larger objective value by %7.2e', t,obj-objGi);
    if obj < objGi
        fprintf(' -- SMALLER!! This shouldn''t happen');
        OK_objective = false;
    end
    fprintf('\n');
end
if ~OK_objective
    fail('TFOCS nonsmooth: incorrect calculation of proximity function');
    return;
end
fprintf('\t\t\t\t...passed. \n');


% 1D example.  Does not require function to be vectorized
n   = 200;  % number of grid points
h   = (b-a)/n;
grid = (a+h/2):h:(b-h/2);
% include "0" so things look nice and pointy:
if a < 0 && b > 0
    grid = unique( [grid,0] );
end
% if isscalar(N)
%     grid = repmat( grid, N, 1 );
% %     grid( 2:end, : ) = 0.5*grid( 2:end, : );
%     grid( 2:end, : ) = 0;
% end

n    =  size(grid,2);
v    = zeros(1,n);
g    = zeros(1,n);
for i = 1:length(grid)
    v(i) = f(grid(1,i) );
    [vi,gi] = f(grid(:,i), t );
    g(i) = gi(1);
end
grid = grid(1,:);
if PLOT
    figure;
    clf;
    plot(grid,v,'-','linewidth',2);
    hold all
    plot(grid,g,'-','linewidth',2);
    Y = get(gca,'ylim');
    Y(2) = 1.1*Y(2);
    set(gca,'ylim',Y);
    
    legend('function','proximity operator');
%     title(func2str(f),'interpreter','none');
    title(sprintf('function, and proximity operator, with parameter t = %.3f',t))
    line([a,b], 0*[1,1],'color','k' )
    if a < 0 && b > 0
        line( 0*[1,1], get(gca,'ylim'),'color','k' );
    end
    % show the y = x line
    line( [a,b], [a,b], 'linestyle','--','color','k');
    
end

OK = true;


disp('Test passed succesfully.');
if nargout > 0
    varargout{1} = OK;
end



function fail(str)
    disp('Test failed.  Reason:');
    disp(str);

% TFOCS v1.3 by Stephen Becker, Emmanuel Candes, and Michael Grant.
% Copyright 2013 California Institute of Technology and CVX Research.
% See the file LICENSE for full license information.
