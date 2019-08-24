function [ x, out, opts ] = tfocs_TS( smoothF, affineF, projectorF, x0, opts )
% TFOCS_TS Tseng's modification of Nesterov's 2007 method.
% [ x, out, opts ] = tfocs_TS( smoothF, affineF, projectorF, x0, opts )
%   Implements Tseng's modification of the Nesterov 2007 method.
%   A variety of calling sequences are supported; type 
%      help tfocs_help
%   for a full explanation.

% Nov 17 2016, hack for Matlab R2016b not allowing nargin/nargout in
% tfocs_initialize:
narginn = nargin; nargoutt = nargout;

% Initialization
alg = 'TS';
algorithm = 'Tseng''s single-projection modification of Nesterov''s 2007 method';
alpha = 0; beta = 0; mu = 0; L = 0; % Necessary due to MATLAB quirk
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
        theta = 2 ./ ( 1 + sqrt( 1 + 4 * L / L_old / theta_old^2 ) );
        
        % Next iterate
        if theta < 1,
              y = ( 1 - theta ) *   x_old + theta *   z_old;
            A_y = ( 1 - theta ) * A_x_old + theta * A_z_old;
            f_y = Inf; g_Ay = []; g_y = []; C_y = Inf;
        end

        % Compute function values
        if isempty( g_y ),
            if isempty( g_Ay ), [ f_y, g_Ay ] = apply_smooth( A_y ); end
            g_y = apply_linear( g_Ay, 2 );
        end

        % Accumulated gradient
        if theta == 1,
            x_cent = x_old;
            g_a = g_y;
        else
            g_a = ( 1 - theta ) * g_a_old + theta * g_y;
        end
        step = 1 / ( theta^2 * L );
        [ C_z, z ] = apply_projector( x_cent - step * g_a, step );
        A_z = apply_linear( z, 1 );
        
        % New iterate
        if theta == 1,
            x   = z; 
            A_x = A_z;
            C_x = C_z;
        else
            x   = ( 1 - theta ) *   x_old + theta *   z;
            A_x = ( 1 - theta ) * A_x_old + theta * A_z;
            C_x = Inf;
        end
        f_x = Inf; g_Ax = []; g_x = [];
        
        % Bactracking test
        tfocs_backtrack
        if do_break, break; end % new, for R2015b compatibility
        
    end
    
    % Collect data, evaluate stopping criteria, and print status
    tfocs_iterate
    if do_break, break; end % new, for R2015b compatibility
    
    g_a_old = g_a;
    
end

% Final processing
tfocs_cleanup

% TFOCS v1.3 by Stephen Becker, Emmanuel Candes, and Michael Grant.
% Copyright 2013 California Institute of Technology and CVX Research.
% See the file LICENSE for full license information.

