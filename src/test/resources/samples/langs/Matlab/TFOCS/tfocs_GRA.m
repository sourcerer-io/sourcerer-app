function [ x, out, opts ] = tfocs_GRA( smoothF, affineF, projectorF, x0, opts )
%TFOCS_GRA Gradient descent.
% [ x, out, opts ] = tfocs_GRA( smoothF, affineF, nonsmoothF, x0, opts )
%   Implements a standard gradient method. A variety of calling sequences
%   are supported; type 'help tfocs_help' for a full explanation.

% Nov 17 2016, hack for Matlab R2016b not allowing nargin/nargout in
% tfocs_initialize:
narginn = nargin; nargoutt = nargout;

% Initialization
alg = 'GRA';
algorithm = 'Proximal gradient descent';
alpha = 0; beta = 0; mu = 0; L = 0; % Do not remove: necessary because of a MATLAB quirk
tfocs_initialize
if nargin==0, return; end

% Unlike the other algorithms, GRA does not use the theta parameter, so it
% is not subject to restart, and we need not embed the initialization code
% inside the loop.

while true,
    
	y     = x; 
    A_y   = A_x;
	f_y   = f_x;
    x_old = x;
    
	g_Ay = g_Ax;
	g_y  = apply_linear( g_Ay, 2 );
    L    = L * alpha;
    
    while true,
    
        % Standard gradient
        [ C_x, x ] = apply_projector( y - (1/L) * g_y, 1/L );
        A_x = apply_linear( x, 1 );
   		[ f_x, g_Ax ] = apply_smooth( A_x );
        
        % Backtracking
        tfocs_backtrack
        if do_break, break; end % new, for R2015b compatibility
        
    end
    
    % Collect data, evaluate stopping criteria, and print status
    tfocs_iterate
    if do_break, break; end % new, for R2015b compatibility
    
end

% Final processing
tfocs_cleanup

% TFOCS v1.3 by Stephen Becker, Emmanuel Candes, and Michael Grant.
% Copyright 2013 California Institute of Technology and CVX Research.
% See the file LICENSE for full license information.
