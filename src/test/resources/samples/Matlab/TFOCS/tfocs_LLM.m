function [ x, out, opts ] = tfocs_LLM( smoothF, affineF, projectorF, x0, opts )
% TFOCS_LLM Lan, Lu and Monteiro's accelerated method.
% [ x, out, opts ] = tfocs_LLM( smoothF, affineF, nonsmoothF, x0, opts )
%   Implements Lan, Lu & Monteiro's method.
%   A variety of calling sequences are supported; type 
%      help tfocs_help
%   for a full explanation.

% Nov 17 2016, hack for Matlab R2016b not allowing nargin/nargout in
% tfocs_initialize:
narginn = nargin; nargoutt = nargout;

% Initialization
alg = 'LLM';
algorithm = 'Lan/Lu/Monteiro''s two-projection method';
alpha = 0; beta = 0; mu =0; L = 0; % Do not remove: necessary due to MATLAB quirk
tfocs_initialize
if nargin == 0, return; end


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
              y = ( 1 - theta ) *   x_old + theta *   z_old;
            A_y = ( 1 - theta ) * A_x_old + theta * A_z_old;
            f_y = Inf; g_Ay = []; g_y = [];
        end
        
        % Compute the latest function values
        if isempty( g_y ),
            if isempty( g_Ay ), [ f_y, g_Ay ] = apply_smooth( A_y ); end
            g_y = apply_linear( g_Ay, 2 );
        end
        
        % Standard gradient
        [ C_x, x ] = apply_projector( y - (1/L) * g_y, 1/L );
        A_x = apply_linear( x, 1 );
        f_x = Inf; g_Ax = []; g_Ax = [];
        
        % Backtracking test
        tfocs_backtrack
        if do_break, break; end % new, for R2015b compatibility
        
    end
    
    % Collect data, evaluate stopping criteria, and print status
    tfocs_iterate
    if do_break, break; end % new, for R2015b compatibility
	
	% Scaled gradient. This step must be skipped if restart occurs
    if theta == 1 || isinf(theta)
        z   = x;
        C_z = C_x;
        A_z = A_x;
    else
    	step = 1 / ( theta * L );
        [ C_z, z ] = apply_projector( z - step * g_y, step );
        A_z = apply_linear( z, 1 );
    end
    
end

% Final processing
tfocs_cleanup

% TFOCS v1.3 by Stephen Becker, Emmanuel Candes, and Michael Grant.
% Copyright 2013 California Institute of Technology and CVX Research.
% See the file LICENSE for full license information.
