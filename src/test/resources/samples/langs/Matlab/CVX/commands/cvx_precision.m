function sout = cvx_precision( flag )

%CVX_PRECISION    Controls CVX solver precision.
%   The CVX_PRECISION command controls the precision-related stopping criteria
%   for the numerical solver. Up to 3 precision levels can be specified:
%       0 <= PBEST <= PHIGH <= PLOW << 1.
%       --- PBEST: the solver's target precision. The solver is instructed
%           to iterate until it achieves this precision OR until it can
%           make no further progress.
%       --- PHIGH: the 'standard' precision level. Any problem achieving
%           PRECISION <= PHIGH is considered accurately solved (returning
%           cvx_status = 'Solved').
%       --- PLOW: the 'minimum acceptable' precision level. Any problem
%           achieving PHIGH < PRECISION <= PLOW is considered inaccurately
%           solved (returning cvx_status = 'Inaccurate/Solved').
%   Problems which cannot achieve PRECISION <= PLOW are considered unsolved
%   (returning cvx_status = 'Failed'). These precision levels apply in
%   appropriate ways to infeasible and unbounded problems as well.
%
%   CVX_PRECISION(TOL), where TOL is a positive scalar, sets
%       PBEST = MAX(TOL,eps^0.5), PHIGH = TOL, 
%       PLOW = min(sqrt(TOL),max(TOL,eps^0.25)).
%   Note that if TOL>eps^0.25, then PLOW=PHIGH.
%
%   CVX_PRECISION(TOL), where TOL is a nonnegative 2-vector, 
%       PBEST = MAX(MIN(TOL),eps^0.5), PHIGH = MIN(TOL), and PLOW = MAX(TOL).
%
%   CVX_PRECISION(TOL), where TOL is a 3-vector, sets
%       PBEST = MIN(TOL), PHIGH = MEDIAN(TOL), and PLOW = MAX(TOL).
%   MIN(TOL) may be zero, but the other two elements must be positive.
%   
%   A number of text-based options are provided for convenience:
%       CVX_PRECISION DEFAULT: [eps^0.5,  eps^0.5,   eps^0.25 ]
%       CVX_PRECISION HIGH   : [eps^0.75, eps^0.75,  eps^0.375] 
%       CVX_PRECISION MEDIUM : [eps^0.5,  eps^0.375, eps^0.25 ]
%       CVX_PRECISION LOW    : [eps^0.5,  eps^0.25,  eps^0.25 ]
%       CVX_PRECISION BEST   : [0,        eps^0.5,   eps^0.25 ]
%
%   CVX_PRECISION([]) is the same as CVX_PRECISION DEFAULT.
%
%   CVX_PRECISION BEST creates a 'best effort' mode. By setting PBSET=0,
%   it instructs the solver to proceed as long as it can make any useful
%   progress. By setting PLOW and PHIGH to their default values, it returns
%   exactly the same CVX_STATUS values as the DEFAULT setting. Therefore,
%   it yields higher precision when it can be achieved, without penalizing
%   models for which it cannot. Of course, higher precision comes at a cost
%   of increased computation time as well.
%
%   If CVX_PRECISION(TOL) is called within a model---that is, between the
%   statements CVX_BEGIN and CVX_END---then the new precision applies only to
%   that particular model. If called outside of a model, then the change 
%   applies to all subsequent models.
%
%   On exit, CVX_PRECISION(TOL) returns the *previous* precision, so that it
%   can be saved and restored later; for example:
%       otol = cvx_precision(tol);
%       cvx_begin
%           ...
%       cvx_end
%       cvx_precision(otol);
%   Of course, this is equivalent to
%       cvx_begin
%           cvx_precision(tol);
%           ...
%       cvx_end
%   but the former syntax it may come in handy if you wish to solve several 
%   models in a row with a different precision.
%
%   CVX_PRECISION, with no arguments, returns the current precision value.

global cvx___
cvx_global
persistent prefvals prefnames
if isempty( prefvals ),
    prefvals = { ...
        [ eps^0.5,   eps^0.5,   eps^0.25  ], ...
        [ eps^0.75,  eps^0.75,  eps^0.375 ], ...
        [ eps^0.5,   eps^0.375, eps^0.25  ], ...
        [ eps^0.375, eps^0.25,  eps^0.25  ], ...
        [ 0,         eps^0.5,   eps^0.25  ] };
    prefnames = { 'default', 'high', 'medium', 'low', 'best' };
end
if nargin > 0,
    if isempty( flag ),
        flag = 'default';
    end
    if ischar( flag ),
        if size( flag, 1 ) ~= 1,
            error( 'Invalid precision string.' );
        else
            ndx = find( strcmpi( flag, prefnames ) );
            if isempty( ndx ),
                error( [ 'Invalid precision mode: ', flag ] );
            else
                flag = prefnames{ndx};
                ns = prefvals{ndx};
            end
        end
    else
        if ~isnumeric( flag ) || numel( flag ) > 3 || length(flag) ~= numel(flag),
            error( 'Argument must be a real number, a 2-vector, a 3-vector, or a string.' );
        elseif any( flag < 0 ) || any( flag >= 1 ),
            error( 'Each precision value must satisfy 0 <= P < 1.' );
        elseif numel( flag ) == 1,
            ns = [ max(flag,eps^0.5), flag, min(sqrt(flag),max(flag,eps^0.25)) ];
        elseif numel( flag ) == 2,
            ns = [ min(flag), min(flag), max(flag) ];
        elseif all( flag == 0 ),
            error( 'At least one precision must be positive.' );
        else
            ns = reshape( sort(flag), 1, 3 );
        end
        ndx = find(cellfun(@(x)all(x==ns),prefvals));
        if isempty(ndx),
            flag = 'custom';
        else
            flag = prefnames{ndx};
        end
    end
end
if isempty( cvx___.problems ),
    s = cvx___.precision;
    f = cvx___.precflag;
    if nargin > 0,
        cvx___.precision = ns;
        cvx___.precflag = flag;
    end
else
    s = cvx___.problems(end).precision;
    f = cvx___.problems(end).precflag;
    if nargin > 0,
        if ~isequal( s, ns ) && ~isa( evalin( 'caller', 'cvx_problem', '[]' ), 'cvxprob' ),
            warning( 'CVX:Precision', 'The global CVX precision setting cannot be changed while a model is being constructed.' );
        else
            cvx___.problems(end).precision = ns;
            cvx___.problems(end).precflag = flag;
        end
    end
end
if nargout > 0,
    sout = s;
elseif nargin == 0,
    fprintf( 'Precision setting: %s\n', f );
    fprintf( '              Solver goal:             precision <= %.2e\n', s(1) );
    fprintf( '               "Solved" if             precision <= %.2e\n', s(2) );
    fprintf( '    "Inaccurate/Solved" if  %.2e < precision <= %.2e\n', s(2), s(3) );
end    

% Copyright 2005-2016 CVX Research, Inc.
% See the file LICENSE.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.
