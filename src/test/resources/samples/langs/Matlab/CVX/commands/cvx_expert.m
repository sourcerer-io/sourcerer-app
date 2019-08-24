function cvx_expert( flag )

%CVX_EXPERT    CVX expert mode.
%   CVX_EXPERT(TRUE) enables certain feature of CVX that have not yet been
%   announced to the general audience due to insufficient testing.
%   Specifically, CVX_EXPERT(TRUE) enables the use of successive
%   approximation methods to handle exponentials, logarithms, and entropy,
%   and changes CVX to solve geometric programs using the same method.
%
%   CVX_EXPERT(FALSE) disables expert mode.
%
%   On exit, CVX_EXPERT(TF) returns the *previous* value of the expert flag,
%   so that it can be flag, so it can be saved and restored later.
%
%   CVX_EXPERT, with no arguments, returns the current flag value.

global cvx___
cvx_global
narginchk(1,1);
if nargin == 1,
    if isnumeric(flag) || islogical(flag),
        ns = double(flag) ~= 0;
    elseif ischar(flag) && size(flag,1) == 1,
        switch lower(flag),
            case 'true',
                ns = true;
            case 'false',
                ns = false;
            otherwise,
                error( 'String arugment must be ''true'' or ''false''.' );
        end
    else
        error( 'Argument must be a numeric scalar or a string.' );
    end
end
cvx___.expert = ns;

% Copyright 2005-2016 CVX Research, Inc.
% See the file LICENSE.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.

