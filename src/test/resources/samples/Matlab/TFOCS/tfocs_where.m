function s = tfocs_where

%TFOCS_WHERE    Returns the location of the TFOCS system.
%   TFOCS_WHERE returns a string containing the base directory of the 
%   TFOCS solvers. Within that directory are some useful
%   subdirectories and files:
%       experiments/     sample TFOCS models
%       COPYING.txt      copyright information
%   The proper operation of this function assumes that it has not been
%   moved from its default position within the TFOCS distribution.

s = mfilename('fullpath');
temp = strfind( s, filesep );
s( temp(end) + 1 : end ) = [];

% TFOCS v1.3 by Stephen Becker, Emmanuel Candes, and Michael Grant.
% Copyright 2013 California Institute of Technology and CVX Research.
% See the file LICENSE for full license information.
