function s = cvx_where

%CVX_WHERE    Returns the location of the CVX system.
%   CVX_WHERE returns a string containing the base directory of the CVX
%   modeling framework. Within that directory are some useful
%   subdirectories and files:
%       functions/    new functions 
%       examples/     sample cvx models
%       LICENSE.txt   copyright information
%   The proper operation of this function assumes that it has not been
%   moved from its default position within the cvx distribution.

try
    s = dbstack('-completenames');
catch
    s = dbstack;
end
s = s(1);
if isfield( s, 'file' ),
    s = s.file;
else
    s = s.name;
end
if ispc, 
    fs = '\'; 
else
    fs = '/'; 
end
temp = strfind( s, fs );
s( temp(end-1) + 1 : end ) = [];

% Copyright 2005-2016 CVX Research, Inc.
% See the file LICENSE.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.
