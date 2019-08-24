function sout = cvx_quiet( flag )

%CVX_QUIET    CVX output control.
%   CVX_QUIET(TRUE) suppresses all text output from CVX (except for error and
%   warning messages). Specifically, solver progress is not printed.
%
%   CVX_QUIET(FALSE) restores full text output.
%
%   If CVX_QUIET(TF) is called within a model---that is, between the statements
%   CVX_BEGIN and CVX_END---then its effect applies only for the current model.
%   If called outside of a model, the change applies to all subsequent models.
%
%   On exit, CVX_QUIET(TF) returns the *previous* value of the quiet flag, so 
%   that it can be saved and restored later; for example:
%       oflag = cvx_quiet(true);
%       cvx_begin
%           ...
%       cvx_end
%       cvx_quiet(oflag);
%   Of course, this is equivalent to
%       cvx_begin
%       cvx_quiet(true);
%           ...
%       cvx_end
%   but the former syntax is handy if you have a script that solves several 
%   models at once. In general it is good practice to make sure that the
%   CVX_QUIET flag is restored to its previous state upon exit from a script,
%   using either of these techniques.
%
%   CVX_QUIET, with no arguments, returns the current flag value.

global cvx___
cvx_global
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
if isempty( cvx___.problems ),
    s = cvx___.quiet;
    if nargin > 0,
        cvx___.quiet = ns;
    end
else
    s = cvx___.problems(end).quiet;
    if nargin > 0,
        if s ~= ns && ~isa( evalin( 'caller', 'cvx_problem', '[]' ), 'cvxprob' ),
            warning( 'CVX:Quiet', 'The global CVX quiet setting cannot be changed while a model is being constructed.' );
        else
            cvx___.problems(end).quiet = ns;
        end
    end
end
if nargin == 0 || nargout > 0,
    sout = s;
end

% Copyright 2005-2016 CVX Research, Inc.
% See the file LICENSE.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.

