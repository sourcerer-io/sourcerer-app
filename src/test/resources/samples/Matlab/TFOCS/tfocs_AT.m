function [ x, out, opts ] = tfocs_AT( smoothF, affineF, projectorF, x0, opts )
% TFOCS_AT Auslender and Teboulle's accelerated method.
% [ x, out, opts ] = tfocs_AT( smoothF, affineF, nonsmoothF, x0, opts )
%   Implements Auslender & Teboulle's method.
%   A variety of calling sequences are supported; type 
%      help tfocs_help
%   for a full explanation.

% Nov 17 2016, hack for Matlab R2016b not allowing nargin/nargout in
% tfocs_initialize:
narginn = nargin; nargoutt = nargout;

% Initialization
alg = 'AT';
algorithm = 'Auslender & Teboulle''s single-projection method';
alpha = 0; beta = 0; mu = 0; L = 0;% Do not remove: necessary because of a MATLAB quirk
tfocs_initialize
if nargin == 0,	return; end

while true,
    
      x_old =   x;
    A_x_old = A_x;
      z_old =   z;
    A_z_old = A_z;
    
    % The backtracking loop
    L_old      = L;
   	L          = L * alpha;
    theta_old  = theta;
    while true,
        
        % Acceleration
        theta = advance_theta( theta_old, L, L_old );

		% Next iterate
        if theta < 1,
            y   = ( 1 - theta ) *   x_old + theta *   z_old;
            if cntr_Ay >= cntr_reset  % change from > to >=, 4/24/14
                % every so often, we compute this explicitly,
                %   to avoid roundoff errors that might accumulate
                A_y = apply_linear( y, 1 );
                cntr_Ay = 0;
            else
                % the efficient way
                cntr_Ay = cntr_Ay + 1;
                A_y = ( 1 - theta ) * A_x_old + theta * A_z_old;
            end
            f_y = Inf; g_Ay = []; g_y = [];
        end
        
        % Compute the function value if it is not already
        if isempty( g_y ),
            if isempty( g_Ay ), [ f_y, g_Ay ] = apply_smooth( A_y ); end
            g_y = apply_linear( g_Ay, 2 );
        end
        
        % Scaled gradient
        step = 1 / ( theta * L );
        [ C_z, z ] = apply_projector( z_old - step * g_y, step );
        A_z = apply_linear( z, 1 );
        
        % New iterate
        if theta == 1,
            x   = z; 
            A_x = A_z;
            C_x = C_z;
        else
            x   = ( 1 - theta ) *   x_old + theta *   z;
            if cntr_Ax >= cntr_reset     % see above comments for cntr_Ay
                cntr_Ax = 0;
                A_x = apply_linear( x, 1 );
            else
                cntr_Ax = cntr_Ax + 1;
                A_x = ( 1 - theta ) * A_x_old + theta * A_z;
            end
            C_x = Inf;
        end
        f_x = Inf; g_Ax = []; g_x = [];
        
        % Perform backtracking tests
        tfocs_backtrack
        if do_break, break; end % new, for R2015b compatibility
        
    end
    
    % Collect data, evaluate stopping criteria, and print status
    tfocs_iterate
    if do_break, break; end
    
end

% Final processing
tfocs_cleanup

% TFOCS v1.3 by Stephen Becker, Emmanuel Candes, and Michael Grant.
% Copyright 2013 California Institute of Technology and CVX Research.
% See the file LICENSE for full license information.
