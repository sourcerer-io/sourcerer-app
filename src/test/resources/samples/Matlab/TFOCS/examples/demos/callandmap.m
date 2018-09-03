function varargout = callandmap(fcn, ix, varargin)
%CALLANDMAP Call a function and rearrange its output arguments
% varargout = callandmap( fcn, ix, varargin )
%
% Suggested here:
%   http://stackoverflow.com/questions/3673392/define-anonymous-function-as-2-of-4-outputs-of-m-file-function

tmp = cell(1,max(ix));        % Capture up to the last argout used
[tmp{:}] = fcn(varargin{:});  % Call the original function
varargout = tmp(ix);          % Remap the outputs

% TFOCS v1.3 by Stephen Becker, Emmanuel Candes, and Michael Grant.
% Copyright 2013 California Institute of Technology and CVX Research.
% See the file LICENSE for full license information.

