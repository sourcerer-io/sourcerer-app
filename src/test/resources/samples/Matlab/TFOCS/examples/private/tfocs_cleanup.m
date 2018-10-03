%SOLVER_CLEANUP    TFOCS helper script
%   Performs the final set of operations for our templated solvers: performs
%   final calculations, prints final outputs, cleans up unused data.

% This should be called just after tfocs_iterate, so re-use some of that
%   computation:

% We have two sequences of points, the x and the y sequence
%   Other things being equal, we will use the x sequence as output
%   But in some cases, if we use y, there is less computation to do
%   since we can re-use some older computation. If it is the case that
%   computing y is cheap, then we will still compute x, but now we will
%   compare x and y and take whichever is better (ties going toward x)

if exist('cur_dual','var')
    cur_dual    = get_dual( cur_dual );
end
if v_is_y && ~output_always_use_x
    % We have some free information about y
    % cur_pri = y
    if data_collection_always_use_x
        % f_vy and dual_y have already been saved
    else
        f_vy    = f_v;
        if saddle, dual_y  = cur_dual; end
    end
end
if ~v_is_x
    if saddle,
        if isempty(g_Ax),
            [ f_x, g_Ax ] = apply_smooth(A_x);
        end
        cur_dual    = get_dual( g_Ax );
    elseif isinf(f_x),
        f_x = apply_smooth(A_x);
    end
    if isinf( C_x ),
        C_x = apply_projector( x );
    end
    f_v         = maxmin * ( f_x + C_x );
    cur_pri     = x;
end
% Now, compare x and y if info on y is available, and take whichever is better
x_or_y_string = 'x';
if v_is_y && ~output_always_use_x
    if f_vy < f_v
        f_v     = f_vy;
        if saddle, cur_dual= dual_y; end
        x       = y; % losing information after this point!
        x_or_y_string = 'y';
    end
end
if saddle
    if ~exist('cur_dual','var')
        if isempty(g_Ax),
            [ f_x, g_Ax ] = apply_smooth(A_x);
        end
        cur_dual    = get_dual( g_Ax );
    end
    out.dual    = cur_dual;
    if isa( out.dual, 'tfocs_tuple')
        out.dual = cell( out.dual );
    end
end
if fid && printEvery,
	fprintf( fid, 'Finished: %s\n', status );
end
out.niter = n_iter;
out.status = status;
out.x_or_y = x_or_y_string;
d.niter = 'Number of iterations';
if saveHist,
    out.f(n_iter) = f_v;
    out.f(n_iter+1:end) = [];
    out.normGrad(n_iter+1:end) = [];
    out.stepsize(n_iter+1:end) = [];
    out.theta(n_iter+1:end,:) = [];
    if countOps,
        out.counts(n_iter+1:end,:) = [];
    end
    if ~isempty(errFcn),
        out.err(n_iter+1:end,:) = [];
    end
    d.f        = 'Objective function history';
    d.normDecr = 'Decrement norm';
    d.stepsize = 'Stepsize';
    d.theta    = 'Acceleration parameter history';
    if countOps,
        d.counts   = strvcat(...
        'k x 4 arry, with columns [F,G,A,P] where',...
        'F: Number of function evaluations of the smooth function',...
        'G: Number of gradient evaluations of the smooth function',...
        'A: Number of calls to the linear operator and its transpose',...
        'N: Number of calls to the nonsmooth function (w/o projection)',...
        'P: Number of calls to the projection operator' );
    end
    if ~isempty(errFcn)
        d.err = 'Error, determined by evaluating the user-supplied error function';
    end
end
out.description = d;
if countOps,
    clear global tfocs_count___
end
    
% TFOCS v1.3 by Stephen Becker, Emmanuel Candes, and Michael Grant.
% Copyright 2013 California Institute of Technology and CVX Research.
% See the file LICENSE for full license information.
