function sout = cvx_pause( flag )

%CVX_PAUSE   Pauses the processing of CVX models.
%   CVX_PAUSE(TRUE) instructs CVX to pause and wait for user keypress before
%   and after proceeding with the numerical solution of a model. The pauses
%   occur within the CVX_END. This is useful for demo purposes.
%
%   CVX_PAUSE(FALSE) ends the pausing behavior.

global cvx___
cvx_global
s = cvx___.pause;
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
    cvx___.pause = ns;
end
if nargin == 0 || nargout > 0,
    sout = s;
end

% Copyright 2005-2016 CVX Research, Inc.
% See the file LICENSE.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.
