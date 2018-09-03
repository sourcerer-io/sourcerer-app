%SOLVER_ITERATE    TFOCS helper script
%	Performs the iterate processing common to all of the first-order solvers
%
%   Major inputs: x, x_old, xy , A_x, A_y, g_Ax, g_Ay 
%       (does not need g_x or g_y really)

% Test for positive stopping criteria
n_iter = n_iter + 1;
norm_x = sqrt( tfocs_normsq( x ) );
norm_dx = sqrt( tfocs_normsq( x - x_old ) );
% We also handle legacy stopping criteria used in the paper:
if stopCrit == 2 && beta >= 1
    % xy_sq not already computed
    xy      = x - y;
    xy_sq   = tfocs_normsq( xy );
end
if isnan( f_y ),
	status = 'NaN found -- aborting';
elseif (stopCrit == 1) && norm_dx  == 0
    if n_iter > 1
        status = 'Step size tolerance reached (||dx||=0)';
    end
elseif (stopCrit == 1) && norm_dx < tol * max( norm_x, 1 ),
    status = 'Step size tolerance reached';
elseif (stopCrit == 2) && L*sqrt(xy_sq) < tol,
    status = 'Step size tolerance reached';
elseif n_iter == maxIts,
	status = 'Iteration limit reached';
elseif countOps && any( tfocs_count___ >= maxCounts ),
	status = 'Function/operator count limit reached';
elseif backtrack_steps > 0 && xy_sq == 0,
    status = sprintf('Unexpectedly small stepsize after %d backtrack steps',backtrack_steps);
end

% for stopCrit 3, we need the new and old dual points
if stopCrit == 3 || stopCrit == 4
    if ~saddle, error('stopCrit = {3,4} requires a saddle point problem'); end
    if exist('cur_dual','var')
        old_dual = cur_dual;
    else
        old_dual = [];
    end
end

%
% For stopping criteria or algorithm control, we assume that the user
% needs the objective function value, but does not wish to do any more
% computation than necessary. So we will use the function value for y
% instead of x if that is cheaper to obtain. So here we determine what
% the additional computational costs will be, and choose the path that
% minimizes them, favoring x in the case of a tie.
%

v_is_x  = false;
v_is_y  = false;
% if isempty(status) && ( ~isempty(stopFcn) || restart < 0 || stopCrit == 3 || stopCrit ==4 ),
if (isempty(status) || ~isempty(findstr(status,'limit')) ) ...
        && ( ~isempty(stopFcn) || restart < 0 || stopCrit == 3 || stopCrit ==4 ),
    need_dual   = saddle && (~isempty(stopFcn) || stopCrit == 3 || stopCrit == 4 );
    comp_x = [ isinf(f_x), need_dual*isempty(g_Ax), isinf(C_x) ];
    comp_y = [ isinf(f_y), need_dual*isempty(g_Ay), isinf(C_y) ];
    if sum(comp_x) <= sum(comp_y) || stopping_criteria_always_use_x,
        if comp_x(2), [f_x,g_Ax] = apply_smooth(A_x);
        elseif comp_x(1), f_x = apply_smooth(A_x); end
        if comp_x(3), C_x = apply_projector(x); end
        cur_pri = x; 
        if saddle, cur_dual = g_Ax; end
        f_v = maxmin*(f_x+C_x);
        v_is_x    = true; % 12/18/2013
    else
        if comp_y(2), [f_y,g_Ay] = apply_smooth(A_y);
        elseif comp_y(1), f_y = apply_smooth(A_y); end
        if comp_y(3), C_y = apply_projector(y); end
        cur_pri = y; 
        if saddle, cur_dual = g_Ay; end
        f_v = maxmin*(f_y+C_y);
        v_is_y    = true;
        if data_collection_always_use_x
            % save the data, otherwise it is overwritten
            f_vy    = f_v;
            if saddle, dual_y  = cur_dual; end
        end
    end
    for err_j = 1 : numel(stopFcn),
        if isa(stopFcn{err_j},'function_handle') % added Oct 27 '14; corrected Aug 22 '17
            if saddle,
                stop = stopFcn{err_j}(f_v,cur_pri, get_dual(cur_dual) );
            else
                stop = stopFcn{err_j}(f_v,cur_pri);
            end
            if stop
                if v_is_x, x_or_y_string = 'x'; else x_or_y_string = 'y'; end
                status = sprintf('Reached user''s supplied stopping criteria no. %d using %s variable',err_j,x_or_y_string);
            end
        end
    end
end

% Now we can apply stopCrit 3 if it has been requested:
if (stopCrit == 3 || stopCrit == 4 ) 
    if ~isempty( old_dual ) && ~isempty( cur_dual )
        d_dual = sqrt(tfocs_normsq( old_dual - cur_dual ));
        if isnumeric( cur_dual ),
             norm_cur = tfocs_normsq( cur_dual );
             norm_old = tfocs_normsq( old_dual );
        else
            norm_cur = 0;
            norm_old = 0;
            for j = 1:max( [1, numel(cur_dual)-1] )
                norm_cur = norm_cur  + tfocs_normsq( cur_dual{j}  );
                norm_old = norm_old  + tfocs_normsq( old_dual{j}  );
            end
        end
        norm_cur = sqrt(norm_cur);
        norm_old = sqrt(norm_old);
    else
        d_dual   = Inf;
        norm_cur = 0; 
        norm_old = 0;
    end
    
	% Note: it is common for the duals to be stuck at zero for quite a few
    %   iterations at the beginning.  In stopCrit = 4 mode, we will not
    %   terminate if both the current and old dual are zero.
    
    if stopCrit == 4
        % for "4", we look at relative change, not absolute change
        if norm_cur > 10*eps && norm_old > 10*eps
            d_dual = d_dual / norm_cur;
        else
            % The dual vectors are zero, so do not terminate.
            % This is equivalent to defining 0/0 = Inf;
            d_dual = Inf;
        end
    end
    nLargeEnough = (n_iter > 2); % Dec '13
    if restart > 10
        nLargeEnough = (n_iter - restart_iter > 2);
    end
    if d_dual < tol  && nLargeEnough
        % Problems when cur_dual is base on x one iteration
        % and y another iteration
        status = 'Step size tolerance reached';
    end
end



%
% Data collection. Since this is used only for algorithm analysis and not
% for algorithm control, we are free to make additional computations here
% without adding them to our total algorithm cost. We prefer to track the
% x sequence in this case, since it is what we will ultimately choose as
% the solution at the end of the algorithm.
%

will_print = fid && printEvery && ...
    ( ~isempty( status ) || ~mod( n_iter, printEvery ) || (printRestart && just_restarted) );
if saveHist || will_print,
    % Which point to collect data at? Dec '13, by default, collect data
    %   at the same point used to find f_v unless data_collection_always_use_x
    % There is also the chance that the f_v wasn't calculated at all
    if ( data_collection_always_use_x && ~v_is_x ) || ( ~v_is_x && ~v_is_y )
        f_x_save = f_x;
        g_Ax_save = g_Ax;
        if ~isempty(errFcn) && saddle,
            if isempty(g_Ax),
                [ f_x, g_Ax ] = smoothF( A_x );
            end
%             out.dual = get_dual( g_Ax );
            cur_dual = g_Ax ;
        end
        if isinf(f_x),
            f_x = smoothF( A_x );
        end
        if isinf( C_x ),
            C_x = projectorF( x );
        end
        f_v         = maxmin * ( f_x + C_x );
        cur_pri     = x;
        v_is_x      = true;
        % Now undo any calculations
        f_x         = f_x_save;
        g_Ax        = g_Ax_save;
    end
    % (otherwise, f_v was already calculated)
    
    if ~isempty(errFcn) && iscell(errFcn)
        errs = zeros(1,numel(errFcn));
        for err_j = 1 : numel(errFcn),
            if saddle,
%                 errs(err_j) = errFcn{err_j}(f_w,x,out.dual);
                % April 14 '14
                %if isempty( get_dual(cur_dual) )
                % March 10 '15
                if isempty(cur_dual) || isempty( get_dual(cur_dual) )
                    errs(err_j) = errFcn{err_j}(f_v,cur_pri,0);
                else
                    errs(err_j) = errFcn{err_j}(f_v,cur_pri,get_dual(cur_dual));
                end
            else
                errs(err_j) = errFcn{err_j}(f_v,cur_pri);
            end
        end
    
        % Oct 27 '14. If stopFcn is a number, then we stop
        %   if errFcn(1) is less than or equal to this number
        if ~isempty(stopFcn)
            for err_j = 1 : numel(stopFcn),
                if isnumeric(stopFcn{err_j})
                    stop = errs(1) <= stopFcn{err_j};
                    if stop
                        status = sprintf(...
                            'Reached user''s supplied stopping criteria of %.2e',stopFcn{err_j});
                    end
                end
            end
        end
    
    end
    
end


% Register a warning if the step size suggests a Lipschitz violation
if isempty(status) && ( beta < 1 && backtrack_simple && localL > Lexact ),
    warning_lipschitz = true;
end	

% Print status
if will_print,
    if warning_lipschitz,
        warning_lipschitz = false;
        bchar = 'L';
    elseif backtrack_simple,
        bchar = ' '; 
    else
        bchar = '*'; 
    end
	fprintf( fid, '%-4d| %+12.5e  %8.2e  %8.2e%c', ...
        n_iter, f_v, norm_dx / max( norm_x, 1 ), 1 / L, bchar );
    if countOps,
        fprintf( fid, '|' );
        fprintf( fid, ' %5d', tfocs_count___ );
    end
    if ~isempty(errFcn),
        if countOps,
            fprintf( fid, ' ' );
        end
    	fprintf( fid, '|' );
        fprintf( fid, ' %8.2e', errs );
    end
    
    
    if printStopCrit
        % Display the number used to determine stopping

        switch stopCrit
            case 1
                if exist('norm_dx','var') && exist('norm_x','var')
                    stopResid   =  norm_dx/max( norm_x,1);
                else
                    stopResid   = Inf;
                end
            case 2
                stopResid   = L*sqrt(xy_sq);
            case {3,4}
                if exist('d_dual','var')
                    stopResid   = d_dual;
                end
            case Inf
                % do nothing
                stopResid = 0;
            otherwise
                error('Bad stopCrit value');
        end
    
        if ~isempty(errFcn) || countOps
            fprintf( fid, ' ' );
        end
        fprintf( fid, '|' );
        fprintf( fid, ' %8.2e', stopResid );
    end
    
    if printRestart && just_restarted
        fprintf( fid, ' | restarted');
    end
    
	fprintf( fid, '\n');
end

% Save history, extending arrays if needed
if saveHist,
    if length(out.f) < n_iter && isempty(status),
        csize = min(maxIts,length(out.f)+1000);
        out.f(end+1:csize,1) = 0;
        out.theta(end+1:csize,1) = 0;
        out.stepsize(end+1:csize,1) = 0;
        out.normGrad(end+1:csize,1) = 0;
        if countOps,
            out.counts(end+1:csize,:) = 0;
        end
        if ~isempty(errs),
            out.err(end+1:csize,:) = 0;
        end
    end
    out.f(n_iter) = f_v;
    out.theta(n_iter) = theta;
    out.stepsize(n_iter) = 1 / L;
    out.normGrad(n_iter) = norm_dx;
    if countOps,
        out.counts(n_iter,:) = tfocs_count___;
    end
    if ~isempty(errFcn),
        out.err(n_iter,:) = errs;
    end
end

% Exit if positive stopping criteria met
% if ~isempty( status ),
% 	break;
% end

% for R2015b compatibility:
do_break    = false;
if ~isempty( status )
    do_break = true;
else

% Restart acceleration if necessary
backtrack_steps = 0;
% "No regress" feature: test was (maxmin*f_v > f_v_old)
%   This worked for minimization, but not for maximization! Dec 15 2010.
% Fixed it.
% two changes: (1) test is now ( maxmin*f_v > maxmin*f_v_old)
%              (2) to reset f_v_old, set to maxmin*Inf, not just +Inf
% Dec 2013, adding gradient-based restarting (see O'Donoghue and Candes '12)
just_restarted  = false;
do_auto_restart = false;
if restart < 0
    if strfind(lower(autoRestart),'gra')
        do_auto_restart = tfocs_dot(g_Ay, A_x - A_x_old ) > 0;
    elseif any(strfind(lower(autoRestart),'fun')) || any(strfind(lower(autoRestart),'obj'))
        do_auto_restart = maxmin*f_v > maxmin*f_v_old;
    else
        error('bad value for opts.autoRestart. Should be ''gradient'' or ''function''');
    end
end
if n_iter - restart_iter == abs(round(restart)) || do_auto_restart
    restart_iter = n_iter;
    backtrack_simple = true;
	theta = Inf;
    y = x; A_y = A_x; f_y = f_x; g_Ay = g_Ax; g_y = g_x; C_y = C_x;
    z = x; A_z = A_x; f_z = f_x; g_Az = g_Ax; g_z = g_x; C_z = C_x;
    f_v_old = maxmin*Inf; % important!
%     continue;
    just_restarted = true;
elseif restart < 0,
    f_v_old = f_v;
end

C_y     = Inf;

end

% TFOCS v1.3 by Stephen Becker, Emmanuel Candes, and Michael Grant.
% Copyright 2013 California Institute of Technology and CVX Research.
% See the file LICENSE for full license information.


