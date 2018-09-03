function sout = cvx_power_warning( flag )

%CVX_POWER_WARNING   Controls the CVX warning message for x.^p expressions.
%   CVX converts power functions like x.^p, for variable x and fixed p, into
%   solvable form using an SOCP transformation. For quadratics x.^2 and square
%   roots x.^(1/2), a single second-order cone is required; for other powers,
%   the number depends on the rational representation of the exponent p.
%
%   CVX_POWER_WARNING(Q) instructs CVX to issue a warning if the resulting
%   transformations requires more than Q second-order cones. The default value
%   is 10, which is not likely to be exceeded for typical choices of P.

global cvx___
cvx_global
if nargin > 0,
    if isempty( flag ),
        ns = 10;
    elseif ~isnumeric( flag ) || ~isreal( flag ) || numel( flag ) > 1 || flag <= 0 || flag ~= floor( flag ),
        error( 'Argument must be a positive integer.' );
    else
        ns = flag;
    end
end
if isempty( cvx___.problems ),
    s = cvx___.rat_growth;
    if nargin > 0,
        cvx___.rat_growth = ns;
    end
else
    s = cvx___.problems(end).rat_growth;
    if nargin > 0,
        if ~isequal( s, ns ) && isa( evalin( 'caller', 'cvx_problem', '[]' ), 'cvxprob' ),
            warning( 'CVX:PowerWarning', 'The global CVX x.^p warning setting cannot be changed while a model is being constructed.' );
        else
            cvx___.problems(end).rat_growth = ns;
        end
    end
end
if nargin == 0 || nargout > 0,
    sout = s;
end

% Copyright 2005-2016 CVX Research, Inc.
% See the file LICENSE.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.
