function maximize( varargin )

%MAXIMIZE Specifiies a concave (or affine) objective to be maximized.

global cvx___
prob = evalin( 'caller', 'cvx_problem', '[]' );
if ~isa( prob, 'cvxprob' ),
    error( 'No CVX model exists in this scope.' );
elseif isempty( cvx___.problems ) || cvx___.problems( end ).self ~= prob,
    error( 'Internal CVX data corruption. Please CLEAR ALL and rebuild your model.' );
elseif nargin < 1,
    error( 'Objective expression missing.' );
elseif iscellstr( varargin ),
    x = evalin( 'caller', sprintf( '%s ', varargin{:} ) );
elseif nargin > 1,
    error( 'Too many input arguments.' );
else
    x = varargin{1};
end
try
    newobj( prob, 'maximize', x );
catch exc
    rethrow( exc )
end

% Copyright 2005-2016 CVX Research, Inc.
% See the file LICENSE.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.
