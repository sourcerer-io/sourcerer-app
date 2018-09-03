function [ x, out, opts ] = tfocs_N07( smoothF, affineF, projectorF, x0, opts )
% TFOCS_N07 Nesterov's 2007 accelerated method.
% [ x, out, opts ] = tfocs_N07( smoothF, affineF, projectorF, x0, opts )
%   Implements Nesterov's 2007 two-projection method.
%   A variety of calling sequences are supported; type 
%      help tfocs_help
%   for a full explanation.

% Nov 17 2016, hack for Matlab R2016b not allowing nargin/nargout in
% tfocs_initialize:
narginn = nargin; nargoutt = nargout;

% Initialization
alg = 'N07';
algorithm = 'Nesterov''s 2007 two-projection method';
alpha = 0; beta = 0; mu = 0; L = 0; % Necessary due to MATLAB quirk
tfocs_initialize
if nargin == 0,return; end

while true,
    
    % Initialize the centerpoint and accumulated gradient. We do this here,
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
              y = ( 1 - theta ) *   x_old + theta *   z_old;
            A_y = ( 1 - theta ) * A_x_old + theta * A_z_old;
            f_y = Inf; g_Ay = []; g_y = [];
        end
        
        % Compute function values
        if isempty( g_y ),
            if isempty( g_Ay ), 
                [ f_y, g_Ay ] = apply_smooth( A_y ); 
            end
            g_y = apply_linear( g_Ay, 2 );
        end

        % Standard gradient
        [ C_x, x ] = apply_projector( y - (1/L) * g_y, 1/L );
        A_x = apply_linear( x, 1 );
        f_x = Inf; g_Ax = []; g_x = [];
        
        % Backtracking test
        tfocs_backtrack
        if do_break, break; end % new, for R2015b compatibility
    end
    
    % Collect data, evaluate stopping criteria, and print status
    tfocs_iterate
    if do_break, break; end % new, for R2015b compatibility
	
	% Accumulated gradient. This step must be skipped if restart occurs
    if theta == 1 || isinf(theta)
        g_accum = g_y;
        x_cent  = x_old;
        z       = x;
        C_z     = C_x;
        A_z     = A_x;
    else
        g_accum = ( 1 - theta ) * g_accum + theta * g_y;
        step = 1 / ( theta^2 * L );
        [ C_z, z ] = apply_projector( x_cent - step * g_accum, step );
        A_z = apply_linear( z, 1 );
    end
    
end

% Final processing
tfocs_cleanup

% TFOCS v1.3 by Stephen Becker, Emmanuel Candes, and Michael Grant.
% Copyright 2013 California Institute of Technology and CVX Research.
% See the file LICENSE for full license information.
