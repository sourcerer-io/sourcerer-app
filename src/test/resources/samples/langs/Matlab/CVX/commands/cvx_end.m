function cvx_end

%CVX_END  Completes a cvx specification.
%   CVX_BEGIN marks the end of a new cvx model, and instructs cvx to
%   complete its processing. For standard, complete models, cvx will send
%   a transformed version of the problem to a solver to obtain numeric
%   results, and replace references to cvx variables with numeric values.

global cvx___
tstart = tic;
prob = evalin( 'caller', 'cvx_problem', '[]' );
if ~isa( prob, 'cvxprob' ),
    error( 'No CVX model exists in this scope.' );
elseif isempty( cvx___.problems ) || cvx___.problems( end ).self ~= prob,
    error( 'Internal CVX data corruption. Please CLEAR ALL and rebuild your model.' );
end
pstr = cvx___.problems( end );
estruc = [];

if isempty( pstr.objective ) && isempty( pstr.variables ) && isempty( pstr.duals ) && nnz( pstr.t_variable ) == 1,

    warning( 'CVX:EmptyModel', 'Empty cvx model; no action taken.' );
    evalin( 'caller', 'pop( cvx_problem, ''none'' )' );

elseif pstr.complete && nnz( pstr.t_variable ) == 1,

    %
    % Check the integrity of the variables
    %

    if isempty( pstr.variables ),
        fn1 = cell( 0, 1 );
        vv1 = fn1;
    else
        fn1  = fieldnames( pstr.variables );
        ndxs = horzcat( fn1{:} );
        ndxs = ndxs( cumsum( cellfun( 'length', fn1 ) ) ) ~= '_';
        fn1  = fn1( ndxs );
        vv1  = struct2cell( pstr.variables );
        vv1  = vv1(ndxs);
    end
    if isempty( pstr.duals ),
        fn2 = cell( 0, 1 );
        vv2 = fn2;
    else
        fn2  = fieldnames( pstr.duals );
        ndxs = horzcat( fn2{:} );
        ndxs = ndxs( cumsum( cellfun( 'length', fn2 ) ) ) ~= '_';
        fn2  = fn2( ndxs );
        vv2  = struct2cell( pstr.dvars );
        vv2  = vv2( ndxs );
    end
    fn1 = [ fn1 ; fn2 ];
    i1  = cvx_ids( vv1{:}, vv2{:} );
    i2  = sprintf( '%s,', fn1{:} );
    try
        i2 = evalin( 'caller', sprintf( 'cvx_ids( %s )', i2(1:end-1) ) );
    catch
        i2 = zeros(1,numel(fn1));
        for k = 1 : length(fn1),
            try
                i2(k) = evalin( 'caller', sprintf( 'cvx_ids( %s )', fn1{k} ) );
            catch
            end
        end
    end
    if any( i1 ~= i2 ),
        evalin( 'caller', 'cvx_clear' );
        temp = sprintf( ' %s', fn1{ i1 ~= i2 } );
        error( 'The following cvx variable(s) have been cleared or overwritten:\n  %s\nThis is often an indication that an equality constraint was\nwritten with one equals ''='' instead of two ''==''. The model\nmust be rewritten before cvx can proceed.', temp ); %#ok
    end

    %
    % Pause
    %

    if cvx___.pause,
        disp( ' ' );
        input( 'Press Enter/Return to call the solver:' );
        disp( ' ' );
    end

    %
    % Compress and solve
    %

    try
        solve( prob );
    catch estruc
    end
    pstr = cvx___.problems( end );

    %
    % Pause again!
    %

    if cvx___.pause && ~cvx___.quiet,
        disp( ' ' );
        input( 'Press Enter/Return to continue:' );
        disp( ' ' );
    end

    %
    % Copy the variable data to the workspace
    %

    if numel( pstr.objective ) > 1 && ~isempty(pstr.result),
        if strfind( pstr.status, 'Solved' ),
            pstr.result = value( pstr.objective );
            if pstr.geometric, pstr.result = exp( pstr.result ); end
        else
            pstr.result = pstr.result * ones(size(pstr.objective));
        end
    end
    % Removed these for simplicity. cvx_optdpt in particular was buggy,
    % and I can't support it. In fact they are for internal use anyway.
    % assignin( 'caller', 'cvx_optpnt',  pstr.variables );
    % assignin( 'caller', 'cvx_optdpt',  pstr.duals );
    assignin( 'caller', 'cvx_status',  pstr.status );
    assignin( 'caller', 'cvx_optval',  pstr.result );
    assignin( 'caller', 'cvx_optbnd',  pstr.bound );
    assignin( 'caller', 'cvx_slvitr',  pstr.iters );
    assignin( 'caller', 'cvx_slvtol',  pstr.tol );
    assignin( 'caller', 'cvx_cputime', cputime - pstr.cputime );
    
    %
    % Compute the numerical values and clear out
    %

    evalin( 'caller', 'pop( cvx_problem, ''value'' )' );

else

    %
    % Determine the parent problem
    %

    p = length( cvx___.problems );
    if p < 2,
        error( 'Internal cvx data corruption.' );
    end
    np = p - 1;

    %
    % Move the variable structure into the parent
    %

    vars = cvx_collapse( pstr.variables, true, false );
    dvars = cvx_collapse( pstr.duals, true, false );
    if ~isempty( vars ) || ~isempty( dvars ),
        pname = [ pstr.name, '_' ];
        if ~isempty( vars ),
            try
                ovars = cvx___.problems(np).variables.(pname);
            catch
                ovars = {};
            end
            ovars{end+1} = vars;
            cvx___.problems(np).variables.(pname) = ovars;
        end
        if ~isempty( dvars ),
            try
                ovars = cvx___.problems(np).duals.(name);
            catch
                ovars = {};
            end
            ovars{end+1} = dvars;
            cvx___.problems(np).duals.(pname) = ovars;
        end
    end

    %
    % Merge the touch information
    %

    v = cvx___.problems( np ).t_variable;
    v = v | pstr.t_variable( 1 : size( v, 1 ), : );
    cvx___.problems( np ).t_variable = v;

    %
    % Process the objective and optimal point, converting to pure
    % epigraph/hypograph form if necessary
    %

    assignin( 'caller', 'cvx_optpnt', cvxtuple( cvx_collapse( vars, false, false ) ) );
    assignin( 'caller', 'cvx_optdpt', cvxtuple( cvx_collapse( dvars, false, false ) ) );
    x = pstr.objective;
    if isempty( x ),

        assignin( 'caller', 'cvx_optval', 0 );
        temp = length( pstr.t_variable ) + 1 : length( cvx___.readonly );
        cvx___.readonly( temp ) = cvx___.readonly( temp ) - 1;

    else

        switch pstr.direction,
            case 'minimize',
                force = false;
                os = +1;
            case 'epigraph',
                force = true;
                os = +1;
            case 'maximize',
                force = false;
                os = -1;
            case 'hypograph',
                force = true;
                os = -1;
        end
        
        if ~force,
            x = sparsify( x, 'objective' );
        end
        xB = cvx_basis( x );
        [ r, c ] = find( xB ); %#ok
        t = r ~= 1; r = r( t );
        cvx___.canslack( r ) = true;

        %
        % Set the vexity flags
        %

        cvx___.vexity( r, : ) = os;
        cvx___.readonly( r, : ) = np;
        
        %
        % Convert to geometric form if necessary
        %

        tt = pstr.geometric;
        if any( tt ),
            if all( tt ),
                x = exp( x );
            else
                x( tt ) = exp( x( tt ) );
            end
        end

        assignin( 'caller', 'cvx_optval', x );
    end

    %
    % Set the status and clear the problem from internal storage
    %

    evalin( 'caller', 'pop( cvx_problem, ''none'' )' );

end

if isempty( cvx___.problems ),
    tfin = tic;
    ptic = pstr.tictime;
    timers = cvx___.timers;
    if isa( timers, 'double' ),
        tfin = double(tfin);
        ptic = double(ptic);
        tstart = double(tstart);
    end
    timers(2) = timers(2) + ( tfin - ptic );
    timers(3) = timers(3) + ( tfin - tstart );
    cvx___.timers = timers;
    profile off;
end

if ~isempty( estruc ),
    if strncmp( estruc.identifier, 'CVX:', 4 ),
        error( estruc.identifier, estruc.message );
    else
        rethrow( estruc );
    end
end

% Copyright 2005-2016 CVX Research, Inc.
% See the file LICENSE.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.
