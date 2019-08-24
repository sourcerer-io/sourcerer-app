function varargout = size( x, dim )

%   Disciplined convex/geometric programming information for SIZE:
%       SIZE imposes no convexity restrictions on its first argument.
%       The second argument, if supplied, must be a positive integer.

s = x.size_;
if nargin > 1,
    if nargout > 1,
        error( 'Too many output arguments.' );
    elseif ~isnumeric( dim ) || length( dim ) ~= 1 || dim <= 0 || dim ~= floor( dim ),
        error( 'Dimension argument must be a positive integer scalar.' );
    elseif dim > length( s ),
        varargout{1} = 1;
    else
        varargout{1} = s(dim);
    end
elseif nargout > 1,
    ns = length( s );
    no = nargout;
    if no > ns,
        s( end+1:no ) = 1;
    elseif no < ns,
        s( no ) = prod( s( no : end ) );
    end
    for k = 1 : no,
        varargout{k} = s(k); %#ok
    end
else
    varargout{1} = s;
end

% Copyright 2005-2016 CVX Research, Inc.
% See the file LICENSE.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.
