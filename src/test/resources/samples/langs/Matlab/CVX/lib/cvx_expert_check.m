function cvx_expert_check( fname, varargin )

global cvx___
if cvx___.expert, return; end
if ~isempty( varargin ) && ~any(cellfun('isclass',varargin,'cvx')), return; end

url = [ 'file:///', cvx___.where, cvx___.fs, 'doc', cvx___.fs, 'advanced.html#the-successive-approximation-method' ];
fprintf( 1, [ 'CVX Warning:\n', ...
'   Models involving "%s" or other functions in the log, exp, and entropy\n', ...
'   family are solved using an experimental successive approximation method.\n', ...
'   This method is slower and less reliable than the method CVX employs for\n', ...
'   other models. Please see the section of the user''s guide entitled\n', ...
'       <a href="%s">The successive approximation method</a>\n', ...
'   for more details about the approach, and for instructions on how to\n', ...
'   suppress this warning message in the future.\n' ], fname, url );

cvx___.expert = true;
    
% Note that we do *not* call cvx_save_prefs here. We only save the
% preferences if an explicit setting of "cvx_expert true" is made.

% Copyright 2005-2016 CVX Research, Inc. 
% See the file LICENSE.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.
