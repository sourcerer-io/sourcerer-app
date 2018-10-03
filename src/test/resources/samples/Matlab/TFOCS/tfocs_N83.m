function [ x, out, opts ] = tfocs_N83( smoothF, affineF, projectorF, x0, opts )
% TFOCS_N83 Nesterov's 1983 accelerated method; also by Beck and Teboulle 2005 (FISTA).
% [ x, out, opts ] = tfocs_N83( smoothF, affineF, nonsmoothF, x0, opts )
%   Implements Nesterov's 1983 method.
%   A variety of calling sequences are supported; type 
%      help tfocs_help
%   for a full explanation.

% Nov 17 2016, hack for Matlab R2016b not allowing nargin/nargout in
% tfocs_initialize:
narginn = nargin; nargoutt = nargout;

% Initialization
alg = 'N83';
algorithm = 'Nesterov''s 1983 single-projection method';
alpha = 0; beta = 0; mu = 0; L = 0; % Do not remove: necessary because of a MATLAB quirk
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
            y   = ( 1 - theta ) *   x_old + theta *   z_old;
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

    % Reversed z update. This step is skipped if restart occurs
    if theta == 1,
        z   =   x;
        A_z = A_x;
        C_z = C_x;
    else
        z   = (1/theta) * x   + ( 1 - 1/theta ) *   x_old;
        A_z = (1/theta) * A_x + ( 1 - 1/theta ) * A_x_old;
        C_z = Inf;
    end
    
end

% Final processing
tfocs_cleanup

% TFOCS v1.3 by Stephen Becker, Emmanuel Candes, and Michael Grant.
% Copyright 2013 California Institute of Technology and CVX Research.
% See the file LICENSE for full license information.
