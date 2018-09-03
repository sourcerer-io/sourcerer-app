function op = prox_Sl1( lambda )
%PROX_SL1    Sorted/Ordered L1 norm.
%    OP = PROX_L1( lambda ) implements the nonsmooth function
%        OP(X) = sum(lambda.*sort(abs(X),'descend'))
%    where lambda is strictly positive and sorted in decreasing order,
%    in which case this function is a norm (and hence convex).
%    If lambda is a scalar, it will be expanded to all elements, but in this
%    case it is equivalent to the (scaled) usual l1 norm.
%    
%    Notice: this function uses mex files. Some pre-compiled binaries
%       for common systems are included; if these do not work for you,
%       then please install yourself. In the mexFiles/ subdirectory,
%       run the file "makeMex.m"
% Reference:
%  http://www-stat.stanford.edu/~candes/OrderedL1/
% "Statistical Estimation and Testing via the Ordered L1 Norm"
% by M. Bogdan, E. van den Berg, W. Su, and E. J. Candès
% 2013
%
% See also prox_l1.m, makeMex.m

if nargin == 0,
	lambda = 1;
elseif ~isnumeric( lambda ) || ~isreal( lambda ) ||  any( lambda <= 0 ) 
	error( 'Argument lambda must have all positive entries.' );
end
if ~issorted(flipud(lambda(:)))
    error( 'Argument lambda must be sorted in decreasing order.');
end
if numel(lambda)==1
    warning('TFOCS:prox_SL1','When lambda is a scalar, we recommend prox_l1.m instead pf prox_SL1.m');
end


% The mex file is in the child directory mexFiles/
% Check for its existence. First, add the right paths
addpath(fullfile(tfocs_where,'mexFiles'));
if 3 ~= exist('proxAdaptiveL1Mex','file')
    makeMex;
    % check that it worked
    if 3 ~= exist('proxAdaptiveL1Mex','file')
        disp('Compilation of mex files for prox_SL1.m failed; please report this error');
    end
end

f       = @(x) sum( lambda(:) .* sort(abs(x(:)), 'descend') );
prox_f  = @(x,t) proxOrderedL1(x,t.*lambda);

op      = tfocs_prox( f, prox_f , 'vector' ); % Allow vector stepsizes


end

% -- subroutines --
function x = proxOrderedL1(y,lambda)
    % Normalization
    lambda = lambda(:);
    y      = y(:);
    sgn    = sign(y);
    [y,idx] = sort(abs(y),'descend');
    
    % Simplify the problem
    k = find(y > lambda,1,'last');
    
    % Compute solution and re-normalize
    n = numel(y);
    x = zeros(n,1);
    
    if (~isempty(k))
        v1 = y(1:k);
        if numel(lambda) > 1
            v2 = lambda(1:k);
        else
            v2 = lambda*ones(k,1); % if lambda is a scalar, implicity make it lambda*ones(size(y))
        end
        v = proxAdaptiveL1Mex(v1,v2);
        x(idx(1:k)) = v;
    end
    
    % Restore signs
    x = sgn .* x;
end


% TFOCS v1.3 by Stephen Becker, Emmanuel Candes, and Michael Grant.
% Copyright 2013 California Institute of Technology and CVX Research.
% See the file LICENSE for full license information.
