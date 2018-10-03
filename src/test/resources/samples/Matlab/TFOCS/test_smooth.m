function varargout = test_smooth( f, N, DOM )
% TEST_SMOOTH Runs diagnostic checks on a TFOCS smooth function object.
% TEST_SMOOTH( F )
%   tests whether the function handle F works as a TFOCS smooth
%   function object.
%
%   Requirements: f = F(X) must return the value of the function at X.
%       [f,g] = F(X) must return the value, f, and the gradient, g.
%
%   For an example, see SMOOTH_QUAD.M
%       
% TEST_SMOOTH( F, N )
%    specifies the size of the domain space.  If N is a scalar,
%    then the domain space is the set of  N x 1 vectors.
%    If N is a matrix of the form [n1, n2], the the domain
%    space is the set of n1 x n2 matrices.
%
% TEST_SMOOTH( ..., DOM )
%    specifies the domain of F.  DOM can be of the form [a,b]
%    which signifies the 1D set (a,b).
%
% OK = TEST_SMOOTH(...)
%    returns "true" if all tests are passed, and "false" otherwise.
%
% See also private/tfocs_smooth, smooth_huber


OK = false;
PLOT = true;

error(nargchk(1,3,nargin));

if ~isa(f,'function_handle')
    fail('TFOCS smooth function must be a FUNCTION HANDLE');
    return; 
end
fprintf('== Testing the smooth function %s ==\n', func2str(f) );

FORCE_N = false;  % always require a vector input
if nargin < 2 || isempty(N),   N = 10;
else FORCE_N = true; 
end
if nargin < 3 || isempty(DOM), DOM = [-1,1];    end

a = DOM(1); b = DOM(2);

x = (a+b)/2;
fprintf('Testing scalar inputs... \n');
try 
    vi = f(x);
catch
    fail('TFOCS smooth function failed to return a function value');
    return;
end
if isinf(vi)
    fail('TFOCS smooth function tester: default domain is invalid. Please specify valid domain');
    return;
end
fprintf('\t\t\t\t...passed. \n');

% Now, also ask for the gradient
fprintf('Testing gradient output... \n');
try 
    [vi,gi] = f(x);
catch
    fail('TFOCS smooth function failed to return a derivative value');
    return;
end
fprintf('\t\t\t\t...passed. \n');

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
    [vi,gi] = f(x);
catch
    fail('TFOCS smooth function failed when supplied a vector input');
    return;
end
fprintf('\t\t\t\t...passed. \n');



% 1D example.  Does not require function to be vectorized
n   = 100;  % number of grid points
h   = (b-a)/n;
grid = (a+h/2):h:(b-h/2);

v    = zeros(size(grid));
g    = zeros(size(grid));
first = @(x) x(1);
for i = 1:length(grid)
    v(i) = f(grid(i));
    if isinf(v(i))
        g(i) = v(i);
    else
        [v(i),gi] = f(grid(i));
        g(i) = first(gi);
    end
end

if PLOT
    figure;
    clf;
    plot(grid,v,'.-');
    hold all
    plot(grid,g,'.-');
    legend('function','derivative');
%     title(func2str(f),'interpreter','none');
    line([a,b], 0*[1,1],'color','k' )
    if a < 0 && b > 0
        line( 0*[1,1], get(gca,'ylim'),'color','k' );
    end
end

OK = true;

if nargout > 0
    varargout{1} = OK;
end

disp('Test passed succesfully.');




function fail(str)
    disp('Test failed.  Reason:');
    disp(str);


% TFOCS v1.3 by Stephen Becker, Emmanuel Candes, and Michael Grant.
% Copyright 2013 California Institute of Technology and CVX Research.
% See the file LICENSE for full license information.
