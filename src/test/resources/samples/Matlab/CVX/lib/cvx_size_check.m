function sz = cvx_size_check( varargin )

%CVX_SIZE_CHECK   Verifies size compatability.
%   SZ = CVX_SIZE_CHECK( ARG1, ..., ARGN ) verifies that the arguments are
%   compatible in size in the same sense as required by the + operator.
%   That is, any arguments that are not scalars must be of the same size.
%   No type checking is performed. The output SZ is the size encountered
%   if the arguments are compatible, or an empty array if they are not.
%   In other words, ISEMPTY(SZ) is true if the arguments are incompatible.

for k = 1 : nargin,
    sz = size( varargin{k} );
    if any( sz ~= 1 ), 
        break; 
    end
end
for j = k+1 : nargin,
    sx = size(varargin{k});
    if any( sx ~= 1 ) && any( sx ~= sz ),
        sz = [];
        break
    end
end

% Copyright 2005-2016 CVX Research, Inc.
% See the file LICENSE.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.
