function [V,D] = safe_eig(X)
% [V,D] = safe_eig(X)
%   calls [V,D] = eig(X) and tests for a common error
%   (http://ask.cvxr.com/t/eig-did-not-converge-in-prox-trace/996/4)
%   and if it finds it, runs a replacement algorithm
try
    [V,D]   = eig(X);
catch ME
    if (strcmpi(ME.identifier,'MATLAB:eig:NoConvergence'))
        [V,D]   = eig_backup(X);
    else
        rethrow(ME);
    end
end