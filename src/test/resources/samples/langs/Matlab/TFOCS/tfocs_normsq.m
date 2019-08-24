function v = tfocs_normsq( x, scaling )

% TFOCS_NORMSQ    Squared norm. 
%    By default, TFOCS_NORMSQ(X) = TFOCS_DOT(X,X). However, certain
%    objects may have more efficient ways of computing this value.
%    If so, TFOCS_NORMSQ should be overloaded to take advantage of
%    this. However, the numerical equivalence to TFOCS_DOT(X,X) must
%    be preserved.
%
%   TFOCS_NORMSQ( X, D ) = TFOCS_DOT( X, D.*X ) is a scaled norm

if nargin < 2 || isempty(scaling)
    v = tfocs_dot( x, x );
elseif numel(scaling) == 1
    v = scaling*tfocs_dot( x, x );
else
    v = tfocs_dot( x, scaling.*x );
end

% TFOCS v1.3 by Stephen Becker, Emmanuel Candes, and Michael Grant.
% Copyright 2013 California Institute of Technology and CVX Research.
% See the file LICENSE for full license information.
